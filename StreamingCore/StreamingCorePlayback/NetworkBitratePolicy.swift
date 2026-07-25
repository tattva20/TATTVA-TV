//
//  NetworkBitratePolicy.swift
//  StreamingCorePlayback
//
//  Copyright by Octavio Rojas all rights reserved.
//

import Foundation
import StreamingCore

public struct NetworkBitratePolicy {
	public init() {}

	/// Preferred peak bit rate (bits per second) to cap playback at for a given
	/// network quality. `0` means no cap — let AVFoundation's ABR pick the maximum.
	public func peakBitRate(for quality: NetworkQuality) -> Double {
		switch quality {
		case .offline, .poor:
			return 600_000
		case .fair:
			return 1_500_000
		case .good:
			return 3_000_000
		case .excellent:
			return 0
		@unknown default:
			return 0
		}
	}
}
