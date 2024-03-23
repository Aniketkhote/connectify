/// Represents a trusted certificate for secure connections.
class TrustedCertificate {
  /// Constructs a [TrustedCertificate] with the provided bytes.
  const TrustedCertificate(this.bytes);

  /// The bytes of the certificate.
  final List<int> bytes;
}
