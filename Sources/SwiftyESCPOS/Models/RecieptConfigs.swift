
// MARK: - Bytes for aligment type

enum kAlignmentType: UInt8 {
    case LeftAlignment   = 48
    case MiddleAlignment = 49
    case RightAlignment  = 50
}

// MARK: - Bytes which recognize printer status

enum kPrinterStatus: UInt8 {
    case PrintStatus       = 0x01
    case OfflineStatus     = 0x02
    case ErrorStatus       = 0x03
    case PaperSensorStatus = 0x04
}

// MARK: - Bytes for setup proper orientation (ex. Arabic right to left style)

enum kPrintOrientation: UInt8 {
    case LeftToRight = 48
    case DownToUP    = 49
    case RightToLeft = 50
    case UpToDown    = 51
}

// MARK: - Bytes for set up each symbol scale. By default it is 0

enum kCharScale: UInt8 {
    case scale_1 = 0
    case scale_2 = 4
    case scale_3 = 34
    case scale_4 = 51
    case scale_5 = 68
    case scale_6 = 85
    case scale_7 = 102
    case scale_8 = 119
}

// MARK: - Bytes that describes type of cutting paper

enum kCutPaperModel: UInt8{
    case fullCut          = 48
    case halfCut          = 49
    case feedPaperHalfCut = 66
}
