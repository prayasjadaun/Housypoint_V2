String _str(Object? v) {
  final s = v?.toString().trim() ?? '';
  return s == 'null' ? '' : s;
}

/// A lending bank — `loan/banks/` (API ref H1).
class BankModel {
  const BankModel({
    required this.id,
    required this.name,
    this.logo = '',
    this.bankType = '',
    this.interestRate = '',
    this.processingFee = '',
    this.prepaymentCharges = '',
    this.amountRange = '',
    this.tenure = '',
    this.description = '',
    this.eligibility = '',
    this.documents = '',
    this.features = '',
    this.process = '',
    this.website = '',
  });

  final int id;
  final String name;
  final String logo;
  final String bankType;
  final String interestRate;
  final String processingFee;
  final String prepaymentCharges;
  final String amountRange;
  final String tenure;
  final String description;
  final String eligibility;
  final String documents;
  final String features;
  final String process;
  final String website;

  factory BankModel.fromJson(Map<String, dynamic> json) => BankModel(
    id: int.tryParse(_str(json['id'])) ?? 0,
    name: _str(json['bank_name']),
    logo: _str(json['bank_logo_url']).isNotEmpty ? _str(json['bank_logo_url']) : _str(json['bank_logo']),
    bankType: _str(json['bank_type']),
    interestRate: _str(json['interest_rate']),
    processingFee: _str(json['processing_fee']),
    prepaymentCharges: _str(json['prepayment_charges']),
    amountRange: _str(json['loan_amount_range']),
    tenure: _str(json['loan_tenure']),
    description: _str(json['description']),
    eligibility: _str(json['eligibility_criteria']),
    documents: _str(json['required_documents']),
    features: _str(json['features_benefits']),
    process: _str(json['application_process']),
    website: _str(json['website_url']),
  );
}
