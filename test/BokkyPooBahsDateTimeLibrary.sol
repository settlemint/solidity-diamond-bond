// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../contracts/libraries/BokkyPooBahsDateTimeLibrary.sol";

contract BokkyPooBahsDateTimeLibraryTest is Test {
    using BokkyPooBahsDateTimeLibrary for uint256;

    function testTimestampFromDate() public {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 expectedTimestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC

        uint256 timestamp = BokkyPooBahsDateTimeLibrary.timestampFromDate(
            year,
            month,
            day
        );
        assertEq(
            timestamp,
            expectedTimestamp,
            "Timestamp from date is incorrect"
        );
    }

    function testTimestampFromDateTime() public {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 hour = 14;
        uint256 minute = 30;
        uint256 second = 0;
        uint256 expectedTimestamp = 1696516200; // Unix timestamp for 2023-10-05 14:30:00 UTC

        uint256 timestamp = BokkyPooBahsDateTimeLibrary.timestampFromDateTime(
            year,
            month,
            day,
            hour,
            minute,
            second
        );
        assertEq(
            timestamp,
            expectedTimestamp,
            "Timestamp from date and time is incorrect"
        );
    }

    function testIsValidDate() public {
        uint256 year = 2023;
        uint256 month = 2;
        uint256 day = 29;
        bool isValid = BokkyPooBahsDateTimeLibrary.isValidDate(
            year,
            month,
            day
        );
        assertFalse(isValid, "Date validation failed for non-leap year");

        year = 2024;
        isValid = BokkyPooBahsDateTimeLibrary.isValidDate(year, month, day);
        assertTrue(isValid, "Date validation failed for leap year");
    }

    function testIsLeapYear() public {
        uint256 timestamp = 1704067200; // Unix timestamp for 2024-01-01 00:00:00 UTC
        bool isLeap = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
        assertTrue(isLeap, "Leap year validation failed for 2024");

        timestamp = 1672444800; // Unix timestamp for 2023-01-01 00:00:00 UTC
        isLeap = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
        assertFalse(isLeap, "Leap year validation failed for 2023");
    }

    function testGetDayOfWeek() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 dayOfWeek = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
        assertEq(dayOfWeek, 4, "Day of week calculation is incorrect"); // 4 = Thursday
    }

    function testAddDays() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 daysToAdd = 5;
        uint256 expectedTimestamp = 1696896000; // Unix timestamp for 2023-10-10 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(
            timestamp,
            daysToAdd
        );
        assertEq(newTimestamp, expectedTimestamp, "Adding days is incorrect");
    }

    function testSubDays() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 daysToSub = 5;
        uint256 expectedTimestamp = 1696032000; // Unix timestamp for 2023-09-30 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subDays(
            timestamp,
            daysToSub
        );
        assertEq(
            newTimestamp,
            expectedTimestamp,
            "Subtracting days is incorrect"
        );
    }
}
