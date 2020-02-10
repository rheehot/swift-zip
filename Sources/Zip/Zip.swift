//
//  Zip.swift
//  
//
//  Created by Jaehong Kang on 2020/02/10.
//

import CoreFoundation
import Foundation
import CMinizip

public struct Zip {
    var data: NSPurgeableData

    public init(contentsOf url: URL) throws {
        let data = try NSPurgeableData(contentsOf: url, options: [])

        self.data = data
    }
}

extension Zip {
    public func getItem(atPath path: String, caseSensitive: Bool = false) throws -> Item? {
        var zipReader: UnsafeMutableRawPointer? = nil

        data.beginContentAccess()
        defer {
            data.endContentAccess()
        }

        mz_zip_reader_create(&zipReader)
        defer {
            mz_zip_reader_delete(&zipReader)
        }

        var error = mz_zip_reader_open_buffer(
            zipReader,
            data.mutableBytes.assumingMemoryBound(to: UInt8.self),
            Int32(data.length),
            0
        )
        defer {
            mz_zip_reader_close(zipReader)
        }

        guard error == MZ_OK else {
            throw Error.unknown(code: Int(error))
        }

        let filenameCString = path.cString(using: .utf8)

        error = mz_zip_reader_locate_entry(zipReader, filenameCString, caseSensitive ? 0 : 1)
        guard error == MZ_OK else {
            if error == MZ_END_OF_LIST {
                return nil
            } else {
                throw Error.unknown(code: Int(error))
            }
        }

        var file: UnsafeMutablePointer<mz_zip_file>?

        error = mz_zip_reader_entry_get_info(zipReader, &file)
        guard error == MZ_OK else {
            throw Error.unknown(code: Int(error))
        }

        let bufferLength = mz_zip_reader_entry_save_buffer_length(zipReader)

        var buffer = [UInt8](repeating: 0x00, count: Int(bufferLength))

        error = mz_zip_reader_entry_save_buffer(zipReader, &buffer, bufferLength)
        guard error == MZ_OK else {
            throw Error.unknown(code: Int(error))
        }

        return .init(path: file.flatMap({ String(cString: $0.pointee.filename) }) ?? path, data: Data(buffer))
    }
}

extension Zip {
    public func unzip(to url: URL) throws {
        guard url.isFileURL else {
            throw Error.invalidURL
        }

        try unzip(toPath: url.path)
    }

    public func unzip(toPath path: String, progressHandler: ((Double) -> Void)? = nil) throws {
        var zipReader: UnsafeMutableRawPointer? = nil

        data.beginContentAccess()
        defer {
            data.endContentAccess()
        }

        mz_zip_reader_create(&zipReader)
        defer {
            mz_zip_reader_delete(&zipReader)
        }

        var error = mz_zip_reader_open_buffer(
            zipReader,
            data.mutableBytes.assumingMemoryBound(to: UInt8.self),
            Int32(data.length),
            0
        )
        defer {
            mz_zip_reader_close(zipReader)
        }

        guard error == MZ_OK else {
            throw Error.unknown(code: Int(error))
        }

        var progressHandler = progressHandler

        let progressCallback: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutablePointer<mz_zip_file>?, Int64) -> Int32 = { (handle, userData, fileInfo, position) in
            var raw = UInt8(0)
            mz_zip_reader_get_raw(handle, &raw)

            guard let fileInfo = fileInfo?.pointee else {
                fatalError()
            }

            let progress: Double
            if (raw > 0 && fileInfo.compressed_size > 0) {
                progress = Double(position) / Double(fileInfo.compressed_size) * 100
            } else if (raw == 0 && fileInfo.uncompressed_size > 0) {
                progress = Double(position) / Double(fileInfo.uncompressed_size) * 100
            } else {
                progress = -1
            }

            userData?.assumingMemoryBound(to: ((Double) -> Void)?.self).pointee?(progress)

            return MZ_OK
        }

        mz_zip_reader_set_progress_cb(zipReader, &progressHandler, progressCallback)
        defer {
            mz_zip_reader_set_progress_cb(zipReader, nil, nil)
        }

        error = mz_zip_reader_save_all(zipReader, path.cString(using: .utf8))
        guard error == MZ_OK || error == MZ_END_OF_LIST else {
            throw Error.unknown(code: Int(error))
        }
    }
}

extension Zip {
    enum Error: Swift.Error {
        case invalidURL
        case unknown(code: Int? = nil)
    }
}

extension Zip {
    public struct Item {
        var path: String
        var data: Data
    }
}
