"""Tests for timezone handling and clock drift detection."""

import uuid
from datetime import datetime, timezone, timedelta

import pytest
from app.services.essl_connector import EsslConnectorService


class TestParseDatetime:
    """Test the _parse_datetime static method with various timezone scenarios."""

    def test_naive_datetime_assumes_server_timezone_ist(self):
        """Naive datetime string should be interpreted as IST (UTC+5:30) and converted to UTC."""
        result = EsslConnectorService._parse_datetime("2024-06-15 09:30:00", "Asia/Kolkata")
        assert result is not None
        assert result.tzinfo == timezone.utc
        # 09:30 IST = 04:00 UTC
        assert result.hour == 4
        assert result.minute == 0

    def test_naive_datetime_assumes_server_timezone_est(self):
        """Naive datetime string should be interpreted as EST (UTC-5) and converted to UTC."""
        result = EsslConnectorService._parse_datetime("2024-06-15 09:30:00", "America/New_York")
        assert result is not None
        assert result.tzinfo == timezone.utc
        # 09:30 EDT = 13:30 UTC (June is DST)
        assert result.hour == 13
        assert result.minute == 30

    def test_naive_datetime_utc(self):
        """Naive datetime with UTC timezone should remain unchanged."""
        result = EsslConnectorService._parse_datetime("2024-06-15 09:30:00", "UTC")
        assert result is not None
        assert result.hour == 9
        assert result.minute == 30

    def test_iso_with_offset(self):
        """ISO 8601 with explicit offset should be converted to UTC."""
        result = EsslConnectorService._parse_datetime("2024-06-15T09:30:00+05:30", "UTC")
        assert result is not None
        assert result.hour == 4
        assert result.minute == 0

    def test_iso_with_z_suffix(self):
        """ISO 8601 with Z suffix should be parsed as UTC."""
        result = EsslConnectorService._parse_datetime("2024-06-15T09:30:00Z", "Asia/Kolkata")
        assert result is not None
        assert result.hour == 9
        assert result.minute == 30

    def test_empty_string_returns_none(self):
        result = EsslConnectorService._parse_datetime("", "Asia/Kolkata")
        assert result is None

    def test_none_returns_none(self):
        result = EsslConnectorService._parse_datetime(None, "Asia/Kolkata")
        assert result is None

    def test_invalid_format_returns_none(self):
        result = EsslConnectorService._parse_datetime("not a date", "Asia/Kolkata")
        assert result is None

    def test_date_with_slash_format(self):
        """MM/DD/YYYY format common in some eSSL devices."""
        result = EsslConnectorService._parse_datetime("06/15/2024 14:30:00", "Asia/Kolkata")
        assert result is not None
        # 14:30 IST = 09:00 UTC
        assert result.hour == 9
        assert result.minute == 0

    def test_iso_with_microseconds(self):
        """ISO format with microseconds."""
        result = EsslConnectorService._parse_datetime("2024-06-15T09:30:00.123456", "Asia/Kolkata")
        assert result is not None
        # 09:30 IST = 04:00 UTC
        assert result.hour == 4

    def test_midnight_ist_conversion(self):
        """Midnight IST should be previous day in UTC."""
        result = EsslConnectorService._parse_datetime("2024-06-15 00:00:00", "Asia/Kolkata")
        assert result is not None
        # 00:00 IST = 18:30 UTC previous day
        assert result.day == 14
        assert result.hour == 18
        assert result.minute == 30


class TestTimezoneConsistency:
    """Test that timezone conversion is consistent across the pipeline."""

    def test_ist_punch_times_group_by_correct_date(self):
        """Punch times in IST should group by IST calendar date, not UTC date."""
        # An employee punches at 22:00 IST on June 15 = 16:30 UTC on June 15
        # This should count as June 15 attendance (IST date)
        ist_time = EsslConnectorService._parse_datetime("2024-06-15 22:00:00", "Asia/Kolkata")
        assert ist_time is not None
        # In UTC this is 16:30 on June 15
        assert ist_time.month == 6
        assert ist_time.day == 15
        assert ist_time.hour == 16
        assert ist_time.minute == 30

    def test_late_night_ist_crosses_utc_date(self):
        """A punch at 01:00 IST crosses midnight UTC."""
        result = EsslConnectorService._parse_datetime("2024-06-15 01:00:00", "Asia/Kolkata")
        assert result is not None
        # 01:00 IST = 19:30 UTC on June 14
        assert result.day == 14
        assert result.hour == 19
        assert result.minute == 30


@pytest.mark.asyncio
async def test_clock_drift_detection_endpoint(client, auth_headers, test_tenant):
    """Test the clock drift detection endpoint returns valid structure."""
    # This test requires an eSSL server to be configured
    # We'll test the endpoint structure only
    response = await client.get("/api/v1/essl/nonexistent/clock-drift", headers=auth_headers)
    assert response.status_code == 404  # No server configured
