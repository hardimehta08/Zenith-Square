import calendar
from datetime import date
from decimal import Decimal


def _count_overdue_months(due_date):
    """
    Count the number of full calendar months a bill is overdue.
    Safely clamps day-of-month (e.g., Jan 31 -> Feb 28/29 -> Mar 31).
    Returns 0 if due_date is today or in the future, or if less than
    one full calendar month has elapsed since due_date.
    """
    today = date.today()
    if due_date >= today:
        return 0

    months = 0
    while True:
        target_month = due_date.month + months + 1
        target_year = due_date.year + (target_month - 1) // 12
        target_month = ((target_month - 1) % 12) + 1
        max_day = calendar.monthrange(target_year, target_month)[1]
        next_due = date(target_year, target_month, min(due_date.day, max_day))

        if next_due > today:
            break
        months += 1

    return months


def calculate_late_fee(base_amount, due_date, late_fee_percent):
    """
    Monthly recurring late fee:
    For every full calendar month past due_date, add late_fee_percent once.
    Returns (overdue_months, late_fee_amount).
    """
    if not late_fee_percent:
        return 0, Decimal('0.00')
    months = _count_overdue_months(due_date)
    if months == 0:
        return 0, Decimal('0.00')
    total_percent = Decimal(str(late_fee_percent)) * months
    late_fee = round((Decimal(str(base_amount)) * total_percent) / Decimal('100'), 2)
    return months, late_fee
