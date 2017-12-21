//
//  LockTestTests.swift
//  LockTestTests
//
//  Created by Max on 2017/12/21.
//  Copyright © 2017年 youzu. All rights reserved.
//

import XCTest

class LockTestTests: XCTestCase {
    
    let times = 1000*10000
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testNSLock()
    {
        let lock = NSLock()
        
        self.measure {
            for _ in 0...times
            {
                lock.lock()
                lock.unlock()
            }
        }
    }
    
    func testRecursiveLock()
    {
        let lock = NSRecursiveLock()
        
        self.measure {
            for _ in 0...times
            {
                lock.lock()
                lock.unlock()
            }
        }
    }
    
    func testCondition()
    {
        let lock = NSCondition()
        
        self.measure {
            for _ in 0...times
            {
                lock.lock()
                lock.unlock()
            }
        }
    }
    
    func testConditionLock()
    {
        let lock = NSConditionLock()
        
        self.measure {
            for _ in 0...times
            {
                lock.lock()
                lock.unlock()
            }
        }
    }
    
    func testOsUnfairLock()
    {
        let osUnfairLock = os_unfair_lock_t.allocate(capacity: 1)
        osUnfairLock.pointee = os_unfair_lock_s()
        self.measure {
            for _ in 0...times
            {
                os_unfair_lock_lock(osUnfairLock)
                os_unfair_lock_unlock(osUnfairLock)
            }
        }
    }
    
    func testOsSpinLock()
    {
        let osSpinLock = UnsafeMutablePointer<OSSpinLock>.allocate(capacity: 1)
        osSpinLock.pointee = OS_SPINLOCK_INIT
        self.measure {
            for _ in 0...times
            {
                OSSpinLockLock(osSpinLock)
                OSSpinLockUnlock(osSpinLock)
            }
        }
    }
    
    func testPthreadMutex()
    {
        let pointer = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        pointer.pointee = pthread_mutex_t()
        pthread_mutex_init(pointer, nil)
        
        self.measure {
            for _ in 0...times
            {
                pthread_mutex_lock(pointer)
                pthread_mutex_unlock(pointer)
            }
        }
        
        pthread_mutex_destroy(pointer)
    }
    
    func testSemaphore()
    {
        let semaphore = DispatchSemaphore.init(value: 1);
        
        self.measure {

            for _ in 0...times
            {
                semaphore.wait()
                semaphore.signal()
            }
        }
    }
    
    func testSynchronized()
    {
        self.measure {
            for _ in 0...times
            {
                objc_sync_enter(self)
                
                objc_sync_exit(self)
            }
        }
    }
}
