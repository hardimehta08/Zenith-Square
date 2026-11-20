import datetime
import re
from decimal import Decimal
from rest_framework import serializers
from .models import (
    MaintenanceBill,
    PaymentReceipt,
    SocietyBankDetails,
    SocietyExpenses,
    SocietyIncome,
)
from .late_fees import _count_overdue_months


class MaintenanceBillSerializer(serializers.ModelSerializer):
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True)
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True)
    society_name = serializers.CharField(source='flat.block.society.society_name', read_only=True)

    # Financial Breakdown Fields
    base_amount = serializers.SerializerMethodField()
    late_fee_percent = serializers.SerializerMethodField()
    late_fee_amount = serializers.SerializerMethodField()
    total_payable = serializers.SerializerMethodField()
    is_overdue = serializers.SerializerMethodField()

    class Meta:
        model = MaintenanceBill
        fields = [
            'bill_id',
            'flat_number',
            'block_name',
            'society_name',
            'bill_month',
            'payable_amount',
            'base_amount',
            'late_fee_percent',
            'late_fee_amount',
            'total_payable',
            'due_date',
            'status',
            'is_overdue',
        ]

    def _get_society(self, obj):
        return obj.flat.block.society if (obj.flat and obj.flat.block) else None

    def get_base_amount(self, obj):
        return float(obj.payable_amount)

    def get_is_overdue(self, obj):
        return obj.status.lower() == 'pending' and obj.due_date < datetime.date.today()

    def get_late_fee_percent(self, obj):
        if not self.get_is_overdue(obj):
            return 0.0
        society = self._get_society(obj)
        if not (society and society.late_fee_percent):
            return 0.0
        months = _count_overdue_months(obj.due_date)
        if months == 0:
            return 0.0
        return float(Decimal(str(society.late_fee_percent)) * months)

    def get_late_fee_amount(self, obj):
        if not self.get_is_overdue(obj):
            return 0.0
        society = self._get_society(obj)
        if not (society and society.late_fee_percent):
            return 0.0
        months = _count_overdue_months(obj.due_date)
        if months == 0:
            return 0.0
        total_percent = Decimal(str(society.late_fee_percent)) * months
        return float(round((Decimal(str(obj.payable_amount)) * total_percent) / Decimal('100'), 2))

    def get_total_payable(self, obj):
        base = Decimal(str(obj.payable_amount))
        late_fee = Decimal(str(self.get_late_fee_amount(obj)))
        return float(base + late_fee)


class PaymentReceiptSerializer(serializers.ModelSerializer):
    bill_month = serializers.CharField(source='payment.bill.bill_month', read_only=True)
    amount = serializers.DecimalField(source='payment.amount', max_digits=10, decimal_places=2, read_only=True)
    payment_method = serializers.CharField(source='payment.payment_method', read_only=True)
    payment_date = serializers.DateTimeField(source='payment.payment_date', read_only=True)
    payment_id = serializers.CharField(source='payment.payment_id', read_only=True)
    payment_status = serializers.CharField(source='payment.status', read_only=True)
    payment_type = serializers.CharField(source='payment.payment_type', read_only=True)
    payer_name = serializers.SerializerMethodField()
    flat_number = serializers.SerializerMethodField()
    block_name = serializers.SerializerMethodField()
    society_name = serializers.SerializerMethodField()
    society_address = serializers.SerializerMethodField()
    society_city = serializers.SerializerMethodField()
    society_pincode = serializers.SerializerMethodField()
    society_email = serializers.SerializerMethodField()
    society_phone = serializers.SerializerMethodField()

    def _get_flat(self, obj):
        payment = obj.payment
        if not payment:
            return None

        bill = payment.bill
        if bill and bill.flat:
            return bill.flat
        return payment.resident.flat if payment.resident else None

    def _get_society(self, obj):
        flat = self._get_flat(obj)
        return flat.block.society if flat and flat.block else None

    def get_payer_name(self, obj):
        payment = obj.payment
        if not payment:
            return ''

        bill_payer = payment.bill.payer if payment.bill else None
        if bill_payer and bill_payer.user_name:
            return bill_payer.user_name

        resident_user = payment.resident.user if payment.resident else None
        if resident_user and resident_user.user_name:
            return resident_user.user_name
        return ''

    def get_flat_number(self, obj):
        flat = self._get_flat(obj)
        return flat.flat_number if flat else ''

    def get_block_name(self, obj):
        flat = self._get_flat(obj)
        return flat.block.block_name if flat and flat.block else ''

    def get_society_name(self, obj):
        society = self._get_society(obj)
        return society.society_name if society else ''

    def get_society_address(self, obj):
        society = self._get_society(obj)
        return society.society_address if society else ''

    def get_society_city(self, obj):
        society = self._get_society(obj)
        return society.society_city if society else ''

    def get_society_pincode(self, obj):
        society = self._get_society(obj)
        return society.society_pincode if society else ''

    def get_society_email(self, obj):
        society = self._get_society(obj)
        return (society.society_email or '') if society else ''

    def get_society_phone(self, obj):
        society = self._get_society(obj)
        return (society.society_phone or '') if society else ''

    class Meta:
        model = PaymentReceipt
        fields = [
            'receipt_id',
            'receipt_number',
            'bill_month',
            'amount',
            'payment_method',
            'payment_date',
            'payment_id',
            'payment_status',
            'payment_type',
            'generated_at',
            'payer_name',
            'flat_number',
            'block_name',
            'society_name',
            'society_address',
            'society_city',
            'society_pincode',
            'society_email',
            'society_phone',
        ]


class SocietyBankDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocietyBankDetails
        fields = [
            'account_name',
            'bank_name',
            'account_number',
            'ifsc_code',
            'branch',
            'upi_id',
        ]

    def validate_ifsc_code(self, value):
        value = value.strip().upper()
        if not re.fullmatch(r'[A-Z]{4}0[A-Z0-9]{6}', value):
            raise serializers.ValidationError('Enter a valid 11-character IFSC code.')
        return value

    def validate_account_number(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Account number is required.')
        return value

    def validate(self, attrs):
        for field in ('account_name', 'bank_name', 'branch'):
            if field in attrs:
                attrs[field] = attrs[field].strip()
                if not attrs[field]:
                    raise serializers.ValidationError(
                        {field: 'This field cannot be blank.'}
                    )
        if 'upi_id' in attrs:
            attrs['upi_id'] = attrs['upi_id'].strip()
        return attrs


class SocietyExpensesSerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(source='society.society_name', read_only=True)
    society_city = serializers.CharField(source='society.society_city', read_only=True)
    expense_type = serializers.CharField(
        max_length=50,
        min_length=3,
        trim_whitespace=True,
        error_messages={
            'required': 'Expense category or title is required.',
            'blank': 'Expense category cannot be blank.',
            'min_length': 'Expense title must be at least 3 characters.',
        }
    )
    amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=Decimal('0.01'),
        error_messages={
            'required': 'Expense amount is required.',
            'min_value': 'Amount must be greater than zero.',
        }
    )
    payment_date = serializers.DateField(
        error_messages={'required': 'Payment date is required.', 'invalid': 'Enter valid date (YYYY-MM-DD).'}
    )
    description = serializers.CharField(
        required=False,
        allow_blank=True,
        allow_null=True,
        trim_whitespace=True
    )

    class Meta:
        model = SocietyExpenses
        fields = ['expense_id', 'expense_type', 'amount', 'payment_date', 'description', 'society_name', 'society_city']
        read_only_fields = ['expense_id', 'society_name', 'society_city']

    def validate_payment_date(self, value):
        if value > datetime.date.today():
            raise serializers.ValidationError('Payment date cannot be in the future.')
        return value


class GenerateMaintenanceBillsSerializer(serializers.Serializer):
    bill_month = serializers.CharField(
        max_length=20,
        min_length=4,
        trim_whitespace=True,
        error_messages={
            'required': 'Billing month name is required (e.g. September 2026).',
            'blank': 'Billing month cannot be blank.'
        }
    )
    due_date = serializers.DateField(
        required=False,
        error_messages={'invalid': 'Enter a valid date (YYYY-MM-DD).'}
    )

    def validate_due_date(self, value):
        if value and value < datetime.date.today():
            raise serializers.ValidationError('Due date cannot be set in the past.')
        return value


class SettlePaymentRequestSerializer(serializers.Serializer):
    bill_id = serializers.CharField(
        max_length=6,
        error_messages={'required': 'bill_id parameter is required.'}
    )
    payment_method = serializers.ChoiceField(
        choices=['ONLINE', 'CASH', 'CHEQUE', 'UPI', 'BANK_TRANSFER'],
        default='ONLINE',
        error_messages={'invalid_choice': 'Invalid payment method selected.'}
    )


class SocietyIncomeSerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(source='society.society_name', read_only=True)
    society_city = serializers.CharField(source='society.society_city', read_only=True)
    income_type = serializers.CharField(
        max_length=50,
        min_length=3,
        trim_whitespace=True,
        error_messages={
            'required': 'Income source or title is required.',
            'blank': 'Income category cannot be blank.',
            'min_length': 'Income title must be at least 3 characters.',
        }
    )
    amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=Decimal('0.01'),
        error_messages={
            'required': 'Income amount is required.',
            'min_value': 'Amount must be greater than zero.',
        }
    )
    received_date = serializers.DateField(
        error_messages={'required': 'Received date is required.', 'invalid': 'Enter valid date (YYYY-MM-DD).'}
    )
    description = serializers.CharField(
        required=False,
        allow_blank=True,
        allow_null=True,
        trim_whitespace=True
    )

    class Meta:
        model = SocietyIncome
        fields = ['income_id', 'income_type', 'amount', 'received_date', 'description', 'society_name', 'society_city']
        read_only_fields = ['income_id', 'society_name', 'society_city']

    def validate_received_date(self, value):
        if value > datetime.date.today():
            raise serializers.ValidationError('Received date cannot be in the future.')
        return value