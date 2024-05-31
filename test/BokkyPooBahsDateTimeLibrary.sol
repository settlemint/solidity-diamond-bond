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

    function testTimestampToDate() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary
            .timestampToDate(timestamp);
        assertEq(year, 2023, "Year is incorrect");
        assertEq(month, 10, "Month is incorrect");
        assertEq(day, 5, "Day is incorrect");
    }

    function testTimestampToDateTime() public {
        uint256 timestamp = 1696518600; // Unix timestamp for 2023-10-05 15:10:00 UTC
        (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        assertEq(year, 2023, "Year is incorrect");
        assertEq(month, 10, "Month is incorrect");
        assertEq(day, 5, "Day is incorrect");
        assertEq(hour, 15, "Hour is incorrect");
        assertEq(minute, 10, "Minute is incorrect");
        assertEq(second, 0, "Second is incorrect");
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

    function testIsValidDateTime() public {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 hour = 14;
        uint256 minute = 30;
        uint256 second = 0;
        bool isValid = BokkyPooBahsDateTimeLibrary.isValidDateTime(
            year,
            month,
            day,
            hour,
            minute,
            second
        );
        assertTrue(isValid, "DateTime validation failed");

        second = 60;
        isValid = BokkyPooBahsDateTimeLibrary.isValidDateTime(
            year,
            month,
            day,
            hour,
            minute,
            second
        );
        assertFalse(isValid, "DateTime validation failed for invalid second");
    }

    function testIsLeapYear() public {
        uint256 timestamp = 1704067200; // Unix timestamp for 2024-01-01 00:00:00 UTC
        bool isLeap = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
        assertTrue(isLeap, "Leap year validation failed for 2024");

        timestamp = 1672444800; // Unix timestamp for 2023-01-01 00:00:00 UTC
        isLeap = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
        assertFalse(isLeap, "Leap year validation failed for 2023");
    }

    function testIsWeekDay() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC (Thursday)
        bool isWeekDay = BokkyPooBahsDateTimeLibrary.isWeekDay(timestamp);
        assertTrue(isWeekDay, "Weekday validation failed for Thursday");

        timestamp = 1696636800; // Unix timestamp for 2023-10-07 00:00:00 UTC (Saturday)
        isWeekDay = BokkyPooBahsDateTimeLibrary.isWeekDay(timestamp);
        assertFalse(isWeekDay, "Weekday validation failed for Saturday");
    }

    function testIsWeekEnd() public {
        uint256 timestamp = 1696636800; // Unix timestamp for 2023-10-07 00:00:00 UTC (Saturday)
        bool isWeekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
        assertTrue(isWeekEnd, "Weekend validation failed for Saturday");

        timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC (Thursday)
        isWeekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
        assertFalse(isWeekEnd, "Weekend validation failed for Thursday");
    }

    function testGetDaysInMonth() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(
            timestamp
        );
        assertEq(
            daysInMonth,
            31,
            "Days in month calculation is incorrect for October"
        );

        timestamp = 1704067200; // Unix timestamp for 2024-01-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(
            daysInMonth,
            31,
            "Days in month calculation is incorrect for January"
        );

        timestamp = 1706745600; // Unix timestamp for 2024-02-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(
            daysInMonth,
            29,
            "Days in month calculation is incorrect for February in a leap year"
        );

        timestamp = 1672531200; // Unix timestamp for 2023-01-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(
            daysInMonth,
            31,
            "Days in month calculation is incorrect for January in a non-leap year"
        );

        timestamp = 1675209600; // Unix timestamp for 2023-02-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(
            daysInMonth,
            28,
            "Days in month calculation is incorrect for February in a non-leap year"
        );
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

    function testAddMonths() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 monthsToAdd = 3;
        uint256 expectedTimestamp = 1704412800; // Unix timestamp for 2024-01-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(
            timestamp,
            monthsToAdd
        );
        assertEq(newTimestamp, expectedTimestamp, "Adding months is incorrect");
    }

    function testSubMonths() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 monthsToSub = 3;
        uint256 expectedTimestamp = 1688515200; // Unix timestamp for 2023-07-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subMonths(
            timestamp,
            monthsToSub
        );
        assertEq(
            newTimestamp,
            expectedTimestamp,
            "Subtracting months is incorrect"
        );
    }

    function testAddYears() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 yearsToAdd = 2;
        uint256 expectedTimestamp = 1759622400; // Unix timestamp for 2025-10-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(
            timestamp,
            yearsToAdd
        );
        assertEq(newTimestamp, expectedTimestamp, "Adding years is incorrect");
    }

    function testSubYears() public {
        uint256 timestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 yearsToSub = 2;
        uint256 expectedTimestamp = 1633392000; // Unix timestamp for 2021-10-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subYears(
            timestamp,
            yearsToSub
        );
        assertEq(
            newTimestamp,
            expectedTimestamp,
            "Subtracting years is incorrect"
        );
    }

    function testDiffDays() public {
        uint256 fromTimestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 toTimestamp = 1696896000; // Unix timestamp for 2023-10-10 00:00:00 UTC
        uint256 diff = BokkyPooBahsDateTimeLibrary.diffDays(
            fromTimestamp,
            toTimestamp
        );
        assertEq(diff, 5, "Difference in days is incorrect");
    }

    function testDiffMonths() public {
        uint256 fromTimestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 toTimestamp = 1704240000; // Unix timestamp for 2024-01-05 00:00:00 UTC
        uint256 diff = BokkyPooBahsDateTimeLibrary.diffMonths(
            fromTimestamp,
            toTimestamp
        );
        assertEq(diff, 3, "Difference in months is incorrect");
    }

    function testDiffYears() public {
        uint256 fromTimestamp = 1696464000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 toTimestamp = 1762291200; // Unix timestamp for 2025-10-05 00:00:00 UTC
        uint256 diff = BokkyPooBahsDateTimeLibrary.diffYears(
            fromTimestamp,
            toTimestamp
        );
        assertEq(diff, 2, "Difference in years is incorrect");
    }
}
