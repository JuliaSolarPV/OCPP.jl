"""
OCPP 1.6 version-specific registries for schema-driven type generation.

These mappings are the only hand-maintained data for V16. Everything else
is derived from the JSON schema files via `generate_types!`.
"""

# ---------------------------------------------------------------------------
# Enum registry: maps sorted value tuples → (EnumTypeName, member_prefix)
# ---------------------------------------------------------------------------

const V16_ENUM_REGISTRY = Dict{Vector{String},Tuple{Symbol,String}}(
    ["Accepted", "Blocked", "ConcurrentTx", "Expired", "Invalid"] =>
        (:AuthorizationStatus, "Authorization"),
    ["Accepted", "Pending", "Rejected"] => (:RegistrationStatus, "Registration"),
    ["Accepted", "Rejected"] => (:GenericStatus, "Generic"),
    ["Accepted", "Rejected", "Scheduled"] => (:AvailabilityStatus, "Availability"),
    ["Inoperative", "Operative"] => (:AvailabilityType, ""),
    ["Accepted", "NotSupported", "RebootRequired", "Rejected"] =>
        (:ConfigurationStatus, "Configuration"),
    ["ChargePointMaxProfile", "TxDefaultProfile", "TxProfile"] =>
        (:ChargingProfilePurposeType, ""),
    ["Accepted", "Unknown"] => (:ClearChargingProfileStatus, "ClearChargingProfile"),
    ["Accepted", "Rejected", "UnknownMessageId", "UnknownVendorId"] =>
        (:DataTransferStatus, "DataTransfer"),
    ["Idle", "UploadFailed", "Uploaded", "Uploading"] =>
        (:DiagnosticsStatus, "Diagnostics"),
    [
        "DownloadFailed",
        "Downloaded",
        "Downloading",
        "Idle",
        "InstallationFailed",
        "Installed",
        "Installing",
    ] => (:FirmwareStatus, "Firmware"),
    ["A", "W"] => (:ChargingRateUnitType, "ChargingRate"),
    [
        "Interruption.Begin",
        "Interruption.End",
        "Other",
        "Sample.Clock",
        "Sample.Periodic",
        "Transaction.Begin",
        "Transaction.End",
        "Trigger",
    ] => (:ReadingContext, "Reading"),
    ["Raw", "SignedData"] => (:ValueFormat, ""),
    ["Body", "Cable", "EV", "Inlet", "Outlet"] => (:Location, "Location"),
    [
        "Current.Export",
        "Current.Import",
        "Current.Offered",
        "Energy.Active.Export.Interval",
        "Energy.Active.Export.Register",
        "Energy.Active.Import.Interval",
        "Energy.Active.Import.Register",
        "Energy.Reactive.Export.Interval",
        "Energy.Reactive.Export.Register",
        "Energy.Reactive.Import.Interval",
        "Energy.Reactive.Import.Register",
        "Frequency",
        "Power.Active.Export",
        "Power.Active.Import",
        "Power.Factor",
        "Power.Offered",
        "Power.Reactive.Export",
        "Power.Reactive.Import",
        "RPM",
        "SoC",
        "Temperature",
        "Voltage",
    ] => (:Measurand, "Measurand"),
    ["L1", "L1-L2", "L1-N", "L2", "L2-L3", "L2-N", "L3", "L3-L1", "L3-N", "N"] =>
        (:Phase, "Phase"),
    [
        "A",
        "Celcius",
        "Celsius",
        "Fahrenheit",
        "K",
        "Percent",
        "V",
        "VA",
        "W",
        "Wh",
        "kVA",
        "kW",
        "kWh",
        "kvar",
        "kvarh",
        "var",
        "varh",
    ] => (:UnitOfMeasure, "Unit"),
    ["Absolute", "Recurring", "Relative"] => (:ChargingProfileKindType, ""),
    ["Daily", "Weekly"] => (:RecurrencyKind, ""),
    ["Accepted", "Faulted", "Occupied", "Rejected", "Unavailable"] =>
        (:ReservationStatus, "Reservation"),
    ["Hard", "Soft"] => (:ResetType, "Reset"),
    ["Differential", "Full"] => (:UpdateType, ""),
    ["Accepted", "Failed", "NotSupported", "VersionMismatch"] =>
        (:UpdateStatus, "Update"),
    ["Accepted", "NotSupported", "Rejected"] =>
        (:ChargingProfileStatus, "ChargingProfile"),
    [
        "ConnectorLockFailure",
        "EVCommunicationError",
        "GroundFailure",
        "HighTemperature",
        "InternalError",
        "LocalListConflict",
        "NoError",
        "OtherError",
        "OverCurrentFailure",
        "OverVoltage",
        "PowerMeterFailure",
        "PowerSwitchFailure",
        "ReaderFailure",
        "ResetFailure",
        "UnderVoltage",
        "WeakSignal",
    ] => (:ChargePointErrorCode, ""),
    [
        "Available",
        "Charging",
        "Faulted",
        "Finishing",
        "Preparing",
        "Reserved",
        "SuspendedEV",
        "SuspendedEVSE",
        "Unavailable",
    ] => (:ChargePointStatus, "ChargePoint"),
    [
        "DeAuthorized",
        "EVDisconnected",
        "EmergencyStop",
        "HardReset",
        "Local",
        "Other",
        "PowerLoss",
        "Reboot",
        "Remote",
        "SoftReset",
        "UnlockCommand",
    ] => (:Reason, "Reason"),
    [
        "BootNotification",
        "DiagnosticsStatusNotification",
        "FirmwareStatusNotification",
        "Heartbeat",
        "MeterValues",
        "StatusNotification",
    ] => (:MessageTrigger, "Trigger"),
    ["Accepted", "NotImplemented", "Rejected"] =>
        (:TriggerMessageStatus, "TriggerMessage"),
    ["NotSupported", "UnlockFailed", "Unlocked"] => (:UnlockStatus, ""),
)

# ---------------------------------------------------------------------------
# Nested object registry: maps JSON property name → Julia type name
# ---------------------------------------------------------------------------

const V16_NESTED_TYPE_NAMES = Dict{String,Symbol}(
    "idTagInfo" => :IdTagInfo,
    "sampledValue" => :SampledValue,
    "meterValue" => :MeterValue,
    "chargingSchedulePeriod" => :ChargingSchedulePeriod,
    "chargingSchedule" => :ChargingSchedule,
    "chargingProfile" => :ChargingProfile,
    "csChargingProfiles" => :ChargingProfile,
    "localAuthorizationList" => :AuthorizationData,
    "configurationKey" => :KeyValueType,
    "transactionData" => :MeterValue,
)
