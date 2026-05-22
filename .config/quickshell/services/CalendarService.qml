pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property int todayYear:  new Date().getFullYear()
    readonly property int todayMonth: new Date().getMonth()
    readonly property int todayDate:  new Date().getDate()

    property int currentYear:  todayYear
    property int currentMonth: todayMonth

    readonly property int gridRows: 6

    readonly property string monthHeader: Qt.formatDateTime(new Date(currentYear, currentMonth, 1), "MMMM yyyy")

    readonly property var weekNumbers: monthData(currentYear, currentMonth).weekNumbers
    readonly property var dayGrid:     monthData(currentYear, currentMonth).dayGrid

    function prevMonth() {
        if (root.currentMonth === 0) {
            root.currentMonth = 11
            root.currentYear -= 1
        } else {
            root.currentMonth -= 1
        }
    }

    function nextMonth() {
        if (root.currentMonth === 11) {
            root.currentMonth = 0
            root.currentYear += 1
        } else {
            root.currentMonth += 1
        }
    }

    function monthData(year, month) {
        var firstDay = new Date(year, month, 1)
        var daysInMonth = new Date(year, month + 1, 0).getDate()
        var prevMonthDays = new Date(year, month, 0).getDate()

        var startOffset = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1
        var totalCells = Math.ceil((startOffset + daysInMonth) / 7) * 7
        var rows = totalCells / 7

        var grid = []
        var weeks = []

        for (var i = 0; i < totalCells; i++) {
            var col = i % 7
            var cellDay = i - startOffset + 1
            var cellYear = year
            var cellMonth = month
            var isCurrentMonth = true
            var isToday = false
            var isWeekend = (col === 5 || col === 6)

            if (cellDay < 1) {
                cellDay = prevMonthDays + cellDay
                cellMonth = month === 0 ? 11 : month - 1
                cellYear = month === 0 ? year - 1 : year
                isCurrentMonth = false
            } else if (cellDay > daysInMonth) {
                cellDay = cellDay - daysInMonth
                cellMonth = month === 11 ? 0 : month + 1
                cellYear = month === 11 ? year + 1 : year
                isCurrentMonth = false
            }

            if (cellYear === root.todayYear && cellMonth === root.todayMonth && cellDay === root.todayDate) {
                isToday = true
            }

            grid.push({
                day: cellDay,
                month: cellMonth,
                year: cellYear,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isWeekend: isWeekend
            })
        }

        for (var r = 0; r < rows; r++) {
            var rowStartDay = r * 7 - startOffset + 1
            var rowDate = new Date(Date.UTC(year, month, rowStartDay < 1 ? 1 : rowStartDay))
            var thursday = rowDate.getTime() + (3 - ((rowDate.getUTCDay() + 6) % 7)) * 86400000
            var thursDate = new Date(thursday)
            var jan4 = new Date(Date.UTC(thursDate.getUTCFullYear(), 0, 4))
            var weekNum = 1 + Math.round(((thursday - jan4.getTime()) / 86400000 - 3 + ((jan4.getUTCDay() + 6) % 7)) / 7)
            weeks.push(weekNum)
        }

        return { dayGrid: grid, weekNumbers: weeks, rows: rows }
    }
}
