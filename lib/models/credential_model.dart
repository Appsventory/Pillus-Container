enum SshAuthType { password, privateKey }

class CredentialModel {
  final SshAuthType authType;
  final String? password;
  final String? privateKeyPem;
  final String? passphrase;

  const CredentialModel({
    required this.authType,
    this.password,
    this.privateKeyPem,
    this.passphrase,
  });

  Map<String, String> toMap() => {
    'authType': authType.name,
    'password': ?password,
    'privateKeyPem': ?privateKeyPem,
    'passphrase': ?passphrase,
  };

  factory CredentialModel.fromMap(Map<String, dynamic> map) {
    return CredentialModel(
      authType: SshAuthType.values.firstWhere(
        (e) => e.name == map['authType'],
        orElse: () => SshAuthType.password,
      ),
      password: map['password'],
      privateKeyPem: map['privateKeyPem'],
      passphrase: map['passphrase'],
    );
  }
}
