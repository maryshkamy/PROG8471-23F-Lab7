//
//  Double+ToString.swift
//  Lab7MarianaRiosSilveiraCarvalho
//
//  Created by Mariana Rios Silveira Carvalho on 2023-11-08.
//

import Foundation

extension Double {

    // MARK: - Convert a Double to String with double precision
    func toString() -> String {
        return String(format: "%.2f", self)
    }
}
