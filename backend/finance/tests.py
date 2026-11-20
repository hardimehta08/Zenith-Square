from django.test import SimpleTestCase

from .serializers import SocietyBankDetailsSerializer


class SocietyBankDetailsSerializerTests(SimpleTestCase):
    def test_validates_and_normalizes_ifsc(self):
        serializer = SocietyBankDetailsSerializer(data={
            'account_name': '  Zenith Society  ',
            'bank_name': '  Example Bank  ',
            'account_number': ' 1234567890 ',
            'ifsc_code': 'abcd0123456',
            'branch': ' Main Branch ',
            'upi_id': ' society@example ',
        })

        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertEqual(serializer.validated_data['ifsc_code'], 'ABCD0123456')
        self.assertEqual(serializer.validated_data['account_name'], 'Zenith Society')
        self.assertEqual(serializer.validated_data['account_number'], '1234567890')
        self.assertEqual(serializer.validated_data['upi_id'], 'society@example')

    def test_rejects_invalid_ifsc(self):
        serializer = SocietyBankDetailsSerializer(data={
            'account_name': 'Zenith Society',
            'bank_name': 'Example Bank',
            'account_number': '1234567890',
            'ifsc_code': 'BAD',
            'branch': 'Main Branch',
        })

        self.assertFalse(serializer.is_valid())
        self.assertIn('ifsc_code', serializer.errors)
