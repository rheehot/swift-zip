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
    typealias Error = ZipError

    var dataSource: DataSource

    var fileURL: URL? {
        switch dataSource {
        case .filePath(let filePath):
            return .init(fileURLWithPath: filePath)
        case .data:
            return nil
        }
    }

    var data: Data? {
        switch dataSource {
        case .filePath:
            return nil
        case .data(let data):
            return data
        }
    }

    public init(data: Data = .init()) {
        self.dataSource = .data(data)
    }

    public init(contentsOf url: URL) throws {
        if url.isFileURL {
            self.dataSource = .filePath(url.path)
        } else {
            self.dataSource = try .data(.init(contentsOf: url, options: []))
        }
    }
}

extension Zip {
    private func mz_zip_reader_open_zip_data_source(_ handle: UnsafeMutableRawPointer!, _ dataSource: DataSource) -> Int32 {
        switch dataSource {
        case .data(var data):
            return data.withUnsafeMutableBytes {
                return mz_zip_reader_open_buffer(
                    handle,
                    $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    Int32($0.count),
                    0
                )
            }
        case .filePath(let filePath):
            return mz_zip_reader_open_file(
                handle,
                filePath
            )
        }
    }

    public func getItem(atPath path: String, caseSensitive: Bool = false) throws -> Item? {
        var zipReader: UnsafeMutableRawPointer? = nil

        mz_zip_reader_create(&zipReader)
        defer {
            mz_zip_reader_delete(&zipReader)
        }

        var error: Int32 = mz_zip_reader_open_zip_data_source(zipReader, dataSource)
        defer {
            mz_zip_reader_close(zipReader)
        }

        guard error == MZ_OK else {
            throw Error.underlyingMinizipError(code: error)
        }

        let filenameCString = path.cString(using: .utf8)

        error = mz_zip_reader_locate_entry(zipReader, filenameCString, caseSensitive ? 0 : 1)
        guard error == MZ_OK else {
            if error == MZ_END_OF_LIST {
                return nil
            } else {
                throw Error.underlyingMinizipError(code: error)
            }
        }

        var file: UnsafeMutablePointer<mz_zip_file>?

        error = mz_zip_reader_entry_get_info(zipReader, &file)
        guard error == MZ_OK else {
            throw Error.underlyingMinizipError(code: error)
        }

        let bufferLength = mz_zip_reader_entry_save_buffer_length(zipReader)

        var buffer = [UInt8](repeating: 0x00, count: Int(bufferLength))

        error = mz_zip_reader_entry_save_buffer(zipReader, &buffer, bufferLength)
        guard error == MZ_OK else {
            throw Error.underlyingMinizipError(code: error)
        }

        return .init(path: file.flatMap({ String(cString: $0.pointee.filename) }) ?? path, data: Data(buffer))
    }

    public func unzip(to url: URL) throws {
        guard url.isFileURL else {
            throw Error.invalidURL
        }

        try unzip(toPath: url.path)
    }

    public func unzip(toPath path: String, progressHandler: ((Double) -> Void)? = nil) throws {
        var zipReader: UnsafeMutableRawPointer? = nil

        mz_zip_reader_create(&zipReader)
        defer {
            mz_zip_reader_delete(&zipReader)
        }

        var error: Int32 = mz_zip_reader_open_zip_data_source(zipReader, dataSource)
        defer {
            mz_zip_reader_close(zipReader)
        }

        guard error == MZ_OK else {
            throw Error.underlyingMinizipError(code: error)
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
            throw Error.underlyingMinizipError(code: error)
        }
    }
}

extension Zip {
    public struct Item {
        var path: String
        var data: Data
    }
}

extension Zip {
    enum DataSource {
        case data(Data)
        case filePath(String)
    }
}
