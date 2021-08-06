//
//  Constants.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import Foundation

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}


func memoryUsed() -> UInt64 {
    var info = mach_task_basic_info()
    let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
    var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
            task_info(mach_task_self_,
                      task_flavor_t(MACH_TASK_BASIC_INFO),
                      $0,
                      &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        return UInt64(info.resident_size)
    }
    else {
        return 0
    }
}

public func benchmark(name: String = "", _ closure: () -> Void) {
    let memoryBefore = memoryUsed()
    let beforeTime = Date()
    
    closure()
    
    let secondsElapsed = Date().timeIntervalSince(beforeTime)
    let memoryConsumed = (Double(memoryUsed()) - Double(memoryBefore)) / 1024.0 / 1024.0
    
    print("Operation \(name) took \(secondsElapsed) seconds and used \(memoryConsumed) MB of memory")
}
