// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/libraries/BokkyPooBahsDateTimeLibrary.sol";

contract BokkyPooBahsDateTimeLibraryTest is Test {
    using BokkyPooBahsDateTimeLibrary for uint256;

    function testTimestampFromDate() public pure {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 expectedTimestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC

        uint256 timestamp = BokkyPooBahsDateTimeLibrary.timestampFromDate(year, month, day);
        assertEq(timestamp, expectedTimestamp, "Timestamp from date is incorrect");
    }

    function testGetYearMonthDay() public pure {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 timestamp = BokkyPooBahsDateTimeLibrary.timestampFromDate(year, month, day);
        uint256 expectedYear = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
        assertEq(expectedYear, year);
        uint256 expectedMonth = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
        assertEq(expectedMonth, month);
        uint256 expectedDay = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
        assertEq(expectedDay, day);
    }

    function testGetTimeComponents() public pure {
        uint256 timestamp = 1_696_518_600; // Unix timestamp for 2023-10-05 15:10:00 UTC

        uint256 hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
        uint256 minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);
        uint256 second = BokkyPooBahsDateTimeLibrary.getSecond(timestamp);

        assertEq(hour, 15, "Hour extraction is incorrect");
        assertEq(minute, 10, "Minute extraction is incorrect");
        assertEq(second, 0, "Second extraction is incorrect");
    }

    function testDaysFromDate() public pure {
        uint256 day = BokkyPooBahsDateTimeLibrary._daysFromDate(1970, 1, 2);
        assertEq(day, 1);
    }

    function testDaysToDate() public pure {
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary._daysToDate(1);
        assertEq(year, 1970);
        assertEq(month, 1);
        assertEq(day, 2);
    }

    function testTimestampFromDateTime() public pure {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 hour = 14;
        uint256 minute = 30;
        uint256 second = 0;
        uint256 expectedTimestamp = 1_696_516_200; // Unix timestamp for 2023-10-05 14:30:00 UTC

        uint256 timestamp = BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
        assertEq(timestamp, expectedTimestamp, "Timestamp from date and time is incorrect");
    }

    function testTimestampToDate() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        assertEq(year, 2023, "Year is incorrect");
        assertEq(month, 10, "Month is incorrect");
        assertEq(day, 5, "Day is incorrect");
    }

    function testTimestampToDateTime() public pure {
        uint256 timestamp = 1_696_518_600; // Unix timestamp for 2023-10-05 15:10:00 UTC
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) =
            BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        assertEq(year, 2023, "Year is incorrect");
        assertEq(month, 10, "Month is incorrect");
        assertEq(day, 5, "Day is incorrect");
        assertEq(hour, 15, "Hour is incorrect");
        assertEq(minute, 10, "Minute is incorrect");
        assertEq(second, 0, "Second is incorrect");
    }

    function testIsValidDate() public pure {
        uint256 year = 2023;
        uint256 month = 2;
        uint256 day = 29;
        bool isValid = BokkyPooBahsDateTimeLibrary.isValidDate(year, month, day);
        assertFalse(isValid, "Date validation failed for non-leap year");

        year = 2024;
        isValid = BokkyPooBahsDateTimeLibrary.isValidDate(year, month, day);
        assertTrue(isValid, "Date validation failed for leap year");
    }

    function testIsValidDateTime() public pure {
        uint256 year = 2023;
        uint256 month = 10;
        uint256 day = 5;
        uint256 hour = 14;
        uint256 minute = 30;
        uint256 second = 0;
        bool isValid = BokkyPooBahsDateTimeLibrary.isValidDateTime(year, month, day, hour, minute, second);
        assertTrue(isValid, "DateTime validation failed");

        second = 60;
        isValid = BokkyPooBahsDateTimeLibrary.isValidDateTime(year, month, day, hour, minute, second);
        assertFalse(isValid, "DateTime validation failed for invalid second");
    }

    function testIsLeapYear() public pure {
        uint256 timestamp = 1_704_067_200; // Unix timestamp for 2024-01-01 00:00:00 UTC
        bool isLeap = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
        assertTrue(isLeap, "Leap year validation failed for 2024");

        timestamp = 1_672_444_800; // Unix timestamp for 2023-01-01 00:00:00 UTC
        isLeap = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
        assertFalse(isLeap, "Leap year validation failed for 2023");
    }

    function testIsWeekDay() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC (Thursday)
        bool isWeekDay = BokkyPooBahsDateTimeLibrary.isWeekDay(timestamp);
        assertTrue(isWeekDay, "Weekday validation failed for Thursday");

        timestamp = 1_696_636_800; // Unix timestamp for 2023-10-07 00:00:00 UTC (Saturday)
        isWeekDay = BokkyPooBahsDateTimeLibrary.isWeekDay(timestamp);
        assertFalse(isWeekDay, "Weekday validation failed for Saturday");
    }

    function testIsWeekEnd() public pure {
        uint256 timestamp = 1_696_636_800; // Unix timestamp for 2023-10-07 00:00:00 UTC (Saturday)
        bool isWeekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
        assertTrue(isWeekEnd, "Weekend validation failed for Saturday");

        timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC (Thursday)
        isWeekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
        assertFalse(isWeekEnd, "Weekend validation failed for Thursday");
    }

    function testGetDaysInMonth() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(daysInMonth, 31, "Days in month calculation is incorrect for October");

        timestamp = 1_704_067_200; // Unix timestamp for 2024-01-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(daysInMonth, 31, "Days in month calculation is incorrect for January");

        timestamp = 1_706_745_600; // Unix timestamp for 2024-02-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(daysInMonth, 29, "Days in month calculation is incorrect for February in a leap year");

        timestamp = 1_672_531_200; // Unix timestamp for 2023-01-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(daysInMonth, 31, "Days in month calculation is incorrect for January in a non-leap year");

        timestamp = 1_675_209_600; // Unix timestamp for 2023-02-01 00:00:00 UTC
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
        assertEq(daysInMonth, 28, "Days in month calculation is incorrect for February in a non-leap year");
    }

    function testGetDayOfWeek() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 dayOfWeek = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
        assertEq(dayOfWeek, 4, "Day of week calculation is incorrect"); // 4 = Thursday
    }

    function testAddDays() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 daysToAdd = 5;
        uint256 expectedTimestamp = 1_696_896_000; // Unix timestamp for 2023-10-10 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, daysToAdd);
        assertEq(newTimestamp, expectedTimestamp, "Adding days is incorrect");
    }

    function testSubDays() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 daysToSub = 5;
        uint256 expectedTimestamp = 1_696_032_000; // Unix timestamp for 2023-09-30 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subDays(timestamp, daysToSub);
        assertEq(newTimestamp, expectedTimestamp, "Subtracting days is incorrect");
    }

    function testAddMonths() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 monthsToAdd = 3;
        uint256 expectedTimestamp = 1_704_412_800; // Unix timestamp for 2024-01-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, monthsToAdd);
        assertEq(newTimestamp, expectedTimestamp, "Adding months is incorrect");
    }

    function testSubMonths() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 monthsToSub = 3;
        uint256 expectedTimestamp = 1_688_515_200; // Unix timestamp for 2023-07-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subMonths(timestamp, monthsToSub);
        assertEq(newTimestamp, expectedTimestamp, "Subtracting months is incorrect");
    }

    function testAddYears() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 yearsToAdd = 2;
        uint256 expectedTimestamp = 1_759_622_400; // Unix timestamp for 2025-10-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(timestamp, yearsToAdd);
        assertEq(newTimestamp, expectedTimestamp, "Adding years is incorrect");
    }

    function testSubYears() public pure {
        uint256 timestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 yearsToSub = 2;
        uint256 expectedTimestamp = 1_633_392_000; // Unix timestamp for 2021-10-05 00:00:00 UTC

        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subYears(timestamp, yearsToSub);
        assertEq(newTimestamp, expectedTimestamp, "Subtracting years is incorrect");
    }

    function testDiffDays() public pure {
        uint256 fromTimestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 toTimestamp = 1_696_896_000; // Unix timestamp for 2023-10-10 00:00:00 UTC
        uint256 diff = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
        assertEq(diff, 5, "Difference in days is incorrect");
    }

    function testDiffMonths() public pure {
        uint256 fromTimestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 toTimestamp = 1_704_240_000; // Unix timestamp for 2024-01-05 00:00:00 UTC
        uint256 diff = BokkyPooBahsDateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
        assertEq(diff, 3, "Difference in months is incorrect");
    }

    function testDiffYears() public pure {
        uint256 fromTimestamp = 1_696_464_000; // Unix timestamp for 2023-10-05 00:00:00 UTC
        uint256 toTimestamp = 1_762_291_200; // Unix timestamp for 2025-10-05 00:00:00 UTC
        uint256 diff = BokkyPooBahsDateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
        assertEq(diff, 2, "Difference in years is incorrect");
    }

    function testAddTimeComponents() public pure {
        uint256 timestamp = 1_696_518_600; // Unix timestamp for 2023-10-05 14:30:00 UTC

        // Add hours
        uint256 hoursToAdd = 5;
        uint256 expectedTimestampAfterHours = 1_696_536_600; // Unix timestamp for 2023-10-05 19:30:00 UTC
        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.addHours(timestamp, hoursToAdd);
        assertEq(newTimestamp, expectedTimestampAfterHours, "Adding hours is incorrect");

        // Add minutes
        uint256 minutesToAdd = 45;
        uint256 expectedTimestampAfterMinutes = 1_696_521_300; // Unix timestamp for 2023-10-05 15:15:00 UTC
        newTimestamp = BokkyPooBahsDateTimeLibrary.addMinutes(timestamp, minutesToAdd);
        assertEq(newTimestamp, expectedTimestampAfterMinutes, "Adding minutes is incorrect");

        // Add seconds
        uint256 secondsToAdd = 90;
        uint256 expectedTimestampAfterSeconds = 1_696_518_690; // Unix timestamp for 2023-10-05 14:31:30 UTC
        newTimestamp = BokkyPooBahsDateTimeLibrary.addSeconds(timestamp, secondsToAdd);
        assertEq(newTimestamp, expectedTimestampAfterSeconds, "Adding seconds is incorrect");
    }

    function testSubTimeComponents() public pure {
        uint256 timestamp = 1_696_518_600; // Unix timestamp for 2023-10-05 14:30:00 UTC

        // Subtract hours
        uint256 hoursToSub = 5;
        uint256 expectedTimestampAfterHours = 1_696_500_600; // Unix timestamp for 2023-10-05 09:30:00 UTC
        uint256 newTimestamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, hoursToSub);
        assertEq(newTimestamp, expectedTimestampAfterHours, "Subtracting hours is incorrect");

        // Subtract minutes
        uint256 minutesToSub = 45;
        uint256 expectedTimestampAfterMinutes = 1_696_515_900; // Unix timestamp for 2023-10-05 13:45:00 UTC
        newTimestamp = BokkyPooBahsDateTimeLibrary.subMinutes(timestamp, minutesToSub);
        assertEq(newTimestamp, expectedTimestampAfterMinutes, "Subtracting minutes is incorrect");

        // Subtract seconds
        uint256 secondsToSub = 90;
        uint256 expectedTimestampAfterSeconds = 1_696_518_510; // Unix timestamp for 2023-10-05 14:28:30 UTC
        newTimestamp = BokkyPooBahsDateTimeLibrary.subSeconds(timestamp, secondsToSub);
        assertEq(newTimestamp, expectedTimestampAfterSeconds, "Subtracting seconds is incorrect");
    }

    function testDiffTimeComponents() public pure {
        uint256 fromTimestamp = 1_696_516_200; // Unix timestamp for 2023-10-05 14:30:00 UTC
        uint256 toTimestamp = 1_696_546_800; // Unix timestamp for 2023-10-05 23:00:00 UTC

        // Difference in hours
        uint256 expectedDiffHours = 8; // 8 hours difference
        uint256 diffHours = BokkyPooBahsDateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
        assertEq(diffHours, expectedDiffHours, "Difference in hours is incorrect");

        // Difference in minutes
        toTimestamp = 1_696_519_800; // Unix timestamp for 2023-10-05 15:30:00 UTC
        uint256 expectedDiffMinutes = 60; // 60 minutes difference
        uint256 diffMinutes = BokkyPooBahsDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
        assertEq(diffMinutes, expectedDiffMinutes, "Difference in minutes is incorrect");

        // Difference in seconds
        toTimestamp = 1_696_516_260; // Unix timestamp for 2023-10-05 14:31:00 UTC
        uint256 expectedDiffSeconds = 60; // 60 seconds difference
        uint256 diffSeconds = BokkyPooBahsDateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
        assertEq(diffSeconds, expectedDiffSeconds, "Difference in seconds is incorrect");
    }
}
