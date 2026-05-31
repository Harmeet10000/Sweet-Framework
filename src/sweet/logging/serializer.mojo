# Log serializer and sensitive field masking.

struct FieldSerializer(Copyable):
    var field_name: String
    var replacement_prefix: String
    var preserve_suffix: Int

    def __init__(out self, field_name: String, replacement_prefix: String, preserve_suffix: Int = 0):
        self.field_name = field_name
        self.replacement_prefix = replacement_prefix
        self.preserve_suffix = preserve_suffix

    def serialize(self, value: String) -> String:
        if self.preserve_suffix <= 0 or len(value) <= self.preserve_suffix:
            return self.replacement_prefix
        return self.replacement_prefix


struct LogSerializer(Copyable):
    var serializers: List[FieldSerializer]

    def __init__(out self):
        self.serializers = List[FieldSerializer]()

    def register_serializer(mut self, serializer: FieldSerializer):
        self.serializers.append(serializer.copy())

    def register_builtin_sensitive_serializers(mut self):
        self.register_serializer(FieldSerializer("password", "[REDACTED]"))
        self.register_serializer(FieldSerializer("token", "tok_***", 4))
        self.register_serializer(FieldSerializer("credit_card", "****-****-****-", 4))

    def serialize_field(self, key: String, value: String) -> String:
        for i in range(len(self.serializers)):
            if self.serializers[i].field_name == key:
                return self.serializers[i].serialize(value)
        return value

    def apply(mut self, fields: Dict[String, String]) -> Dict[String, String]:
        var result = Dict[String, String]()
        for item in fields.items():
            result[item.key] = self.serialize_field(item.key, item.value)
        return result^
