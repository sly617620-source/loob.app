class CountryCode {
  final String name;
  final String nameAr;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.nameAr,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

final List<CountryCode> countryCodes = [
  const CountryCode(name: 'Yemen', nameAr: 'اليمن', code: 'YE', dialCode: '+967', flag: '🇾🇪'),
  const CountryCode(name: 'Saudi Arabia', nameAr: 'السعودية', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
  const CountryCode(name: 'United Arab Emirates', nameAr: 'الإمارات', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
  const CountryCode(name: 'Kuwait', nameAr: 'الكويت', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
  const CountryCode(name: 'Qatar', nameAr: 'قطر', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
  const CountryCode(name: 'Bahrain', nameAr: 'البحرين', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
  const CountryCode(name: 'Oman', nameAr: 'عُمان', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
  const CountryCode(name: 'Egypt', nameAr: 'مصر', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  const CountryCode(name: 'Jordan', nameAr: 'الأردن', code: 'JO', dialCode: '+962', flag: '🇯🇴'),
  const CountryCode(name: 'Lebanon', nameAr: 'لبنان', code: 'LB', dialCode: '+961', flag: '🇱🇧'),
  const CountryCode(name: 'Iraq', nameAr: 'العراق', code: 'IQ', dialCode: '+964', flag: '🇮🇶'),
  const CountryCode(name: 'Syria', nameAr: 'سوريا', code: 'SY', dialCode: '+963', flag: '🇸🇾'),
  const CountryCode(name: 'Palestine', nameAr: 'فلسطين', code: 'PS', dialCode: '+970', flag: '🇵🇸'),
  const CountryCode(name: 'Sudan', nameAr: 'السودان', code: 'SD', dialCode: '+249', flag: '🇸🇩'),
  const CountryCode(name: 'Morocco', nameAr: 'المغرب', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
  const CountryCode(name: 'Algeria', nameAr: 'الجزائر', code: 'DZ', dialCode: '+213', flag: '🇩🇿'),
  const CountryCode(name: 'Tunisia', nameAr: 'تونس', code: 'TN', dialCode: '+216', flag: '🇹🇳'),
  const CountryCode(name: 'Libya', nameAr: 'ليبيا', code: 'LY', dialCode: '+218', flag: '🇱🇾'),
  const CountryCode(name: 'United States', nameAr: 'الولايات المتحدة', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  const CountryCode(name: 'United Kingdom', nameAr: 'المملكة المتحدة', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  const CountryCode(name: 'Turkey', nameAr: 'تركيا', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
  const CountryCode(name: 'Germany', nameAr: 'ألمانيا', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  const CountryCode(name: 'France', nameAr: 'فرنسا', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  const CountryCode(name: 'China', nameAr: 'الصين', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
  const CountryCode(name: 'India', nameAr: 'الهند', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
];

CountryCode get defaultCountry => countryCodes.first;
