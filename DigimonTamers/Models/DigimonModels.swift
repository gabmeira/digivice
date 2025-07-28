//
//  DigimonModels.swift
//  DigimonTamers
//
//  Created by Gabriel Bruno Meira on 28/07/25.
//

import Foundation

// MARK: - Digimon List Response
struct DigimonListResponse: Codable {
    let content: [DigimonBasic]
    let pageable: Pageable
}

struct DigimonBasic: Codable {
    let id: Int
    let name: String
    let href: String
    let image: String
}

struct Pageable: Codable {
    let currentPage: Int
    let elementsOnPage: Int
    let totalElements: Int
    let totalPages: Int
    let previousPage: String
    let nextPage: String
}

// MARK: - Detailed Digimon Response
struct DigimonDetail: Codable {
    let id: Int
    let name: String
    let xAntibody: Bool
    let images: [DigimonImage]
    let levels: [DigimonLevel]
    let types: [DigimonType]
    let attributes: [DigimonAttribute]
    let fields: [DigimonField]
    let releaseDate: String
    let descriptions: [DigimonDescription]
    let skills: [DigimonSkill]
    let priorEvolutions: [DigimonEvolution]
    let nextEvolutions: [DigimonEvolution]
}

struct DigimonImage: Codable {
    let href: String
    let transparent: Bool
}

struct DigimonLevel: Codable {
    let id: Int
    let level: String
}

struct DigimonType: Codable {
    let id: Int
    let type: String
}

struct DigimonAttribute: Codable {
    let id: Int
    let attribute: String
}

struct DigimonField: Codable {
    let id: Int
    let field: String
    let image: String
}

struct DigimonDescription: Codable {
    let origin: String
    let language: String
    let description: String
}

struct DigimonSkill: Codable {
    let id: Int
    let skill: String
    let translation: String
    let description: String
}

struct DigimonEvolution: Codable {
    let id: Int
    let digimon: String
    let condition: String
    let image: String
    let url: String
}
