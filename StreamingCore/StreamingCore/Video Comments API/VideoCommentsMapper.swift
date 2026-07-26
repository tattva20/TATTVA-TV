//
//  VideoCommentsMapper.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public final class VideoCommentsMapper {
	private struct Root: Decodable {
		private let items: [Item]

		private struct Item: Decodable {
			let id: UUID
			let message: String
			let created_at: Date
			let author: Author
		}

		private struct Author: Decodable {
			let username: String
		}

		var comments: [VideoComment] {
			items.map { VideoComment(id: $0.id, message: $0.message, createdAt: $0.created_at, username: $0.author.username) }
		}
	}

	public enum Error: Swift.Error {
		case invalidData
	}

	public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [VideoComment] {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		guard response.is2xx, let root = try? decoder.decode(Root.self, from: data) else {
			throw Error.invalidData
		}

		return root.comments
	}
}
