/// Represents a trusted certificate for secure connections.
class TrustedCertificate {
  /// The bytes of the certificate.
  final List<int> bytes;

  /// Constructs a [TrustedCertificate] with the provided bytes.
  const TrustedCertificate(this.bytes);
}
