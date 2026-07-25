//
//  XCTestCase+Poll.swift
//  TattvaTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest

extension XCTestCase {
	@MainActor
	@discardableResult
	func poll(until condition: @escaping @MainActor () -> Bool, timeout: TimeInterval = 1) async -> Bool {
		let deadline = Date() + timeout
		while Date() < deadline {
			if condition() { return true }
			await Task.yield()
		}
		return condition()
	}
}
