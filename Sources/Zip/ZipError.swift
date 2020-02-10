//
//  ZipError.swift
//  
//
//  Created by Jaehong Kang on 2020/02/10.
//

import Foundation

public enum ZipError: Error {
    case invalidURL
    case underlyingMinizipError(code: Int32)
}
