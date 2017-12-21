//
//  ViewController.swift
//  LockTest
//
//  Created by youzu_Max on 2017/12/11.
//  Copyright © 2017年 youzu. All rights reserved.
//

/*
 iphone6s 性能测试 1000万次加锁解锁 见单元测试
 
 NSLock:           0.619 sec
 NSRecursiveLock:  0.840
 NSCondition:      0.628
 NSConditionLock   1.637
 osUnfairLock      0.477
 osSpinLock        0.326
 POSIX             0.474
 semaphore         0.414
 @synchronized     2.525
 */

import UIKit

class ViewController: UIViewController {

    let normalLock = NSLock()
    
    //递归锁
    let recursiveLock = NSRecursiveLock()
    
    //集成NSLocking协议 ：NSCondition 的对象实际上作为一个锁和一个线程检查器：锁主要为了当检测条件时保护数据源，执行条件引发的任务；线程检查器主要是根据条件决定是否继续运行线程，即线程是否被阻塞。
    let condition = NSCondition()
    
    //条件锁
    let conditionLock = NSConditionLock()
    
    //iOS10 为替代自旋锁处理的锁
    lazy var osUnfairLock = { () -> UnsafeMutablePointer<os_unfair_lock_s> in
        let osUnfairLock = os_unfair_lock_t.allocate(capacity: 1)
        osUnfairLock.pointee = os_unfair_lock_s()
        return osUnfairLock
    }()
    
    //自旋锁
    lazy var osSpinLock = { () -> UnsafeMutablePointer<OSSpinLock> in
        
        let osSpinLock = UnsafeMutablePointer<OSSpinLock>.allocate(capacity: 1)
        osSpinLock.pointee = OS_SPINLOCK_INIT
        return osSpinLock
    }()
    
    //POSIX
    lazy var pthreadMutex = { () -> UnsafeMutablePointer<pthread_mutex_t> in
        let pointer = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        pointer.pointee = pthread_mutex_t()
        pthread_mutex_init(pointer, nil)
        return pointer
    }()
    
    //pthead 的读写锁
    lazy var pthreadRWLock = { () -> UnsafeMutablePointer<pthread_rwlock_t> in
        let pointer = UnsafeMutablePointer<pthread_rwlock_t>.allocate(capacity: 1)
        pointer.pointee = pthread_rwlock_t()
        pthread_rwlock_init(pointer, nil)
        return pointer
    }()
    
    var i = 0;
    let testQueue = DispatchQueue(label: "Test")
    override func viewDidLoad()
    {
        super.viewDidLoad()
//        self.nslockTest()
//        self.recursiveLockTest()
//        self.conditionTest()
//        self.conditionLockTest()
//        self.osUnfairLockTest()
//        self.osSpinLockTest()
//        self.pthreadMutexTest()
//        self.pthreadRWLockTestB()
    }
    
    func nslockTest()
    {
        DispatchQueue.global().async {
            
            self.normalLock.lock()
            for a in 0...3
            {
                self.test {
                    if a == 1 {
                        self.normalLock.unlock()
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            
            self.normalLock.lock()
            
            print("Pass");
        
            
            self.normalLock.unlock()
        }
    }
    
    // MARK: NSRecursiveLock 递归锁
    func recursiveLockTest()
    {
        for _ in 0...10
        {
            self.recursiveLock.lock()
            self.test {
                self.recursiveLock.unlock()
            }
        }
    }
    
    func conditionTest()
    {
        var goods = Array<Any>()
        
        testQueue.async {
            self.condition.lock()
            
            if goods.count == 0
            {
                self.condition.wait()
            }
            
            for _ in 0...2
            {
                print("buy...")
                sleep(1);
            }
            self.condition.unlock()
        }
        
        DispatchQueue.main.async {
            self.condition.lock()
            for _ in 0...2
            {
                print("product...")
                sleep(1);
            }
            
            goods.append("商品")
            self.condition.signal()
            self.condition.unlock()
        }
    }
    
    // MARK: NSConditionLock 条件锁
    func conditionLockTest()
    {
        
        DispatchQueue.global().async {
            
            self.conditionLock.lock()
            for a in 0...3
            {
                self.test {
                    if a == 1 {
                        self.conditionLock.unlock(withCondition: a)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            
            self.conditionLock.lock(whenCondition: 1)
            
            print("Pass");
            
            self.conditionLock.unlock()
        }
    }

    
    // MARK: osUnfairLock
    
    /// 取代自旋锁出来的东东,实现原理是让线程在内核中挂起，已不是自旋锁了。没有锁优先级和排序，只能统一线程操作（不同线程会直接断言）
    
    func osUnfairLockTest()
    {
        
        DispatchQueue.global().async {
            os_unfair_lock_lock(self.osUnfairLock)
            
            for a in 0...3
            {
                self.test {
                    if a == 1 {
                        os_unfair_lock_unlock(self.osUnfairLock)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            
            os_unfair_lock_lock(self.osUnfairLock)
            
            print("Pass")
            
            os_unfair_lock_unlock(self.osUnfairLock)
            
        }
    }
    
    //MARK: osSpinLock 自旋锁 在不同优先级线程中可能会产生优先级反转的问题 所以苹果弃用了
    func osSpinLockTest()
    {
        DispatchQueue.global().async {
    
            OSSpinLockLock(self.osSpinLock)
            
            for a in 0...3
            {
                self.test {
                    if a == 1 {
                        OSSpinLockUnlock(self.osSpinLock)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            
            OSSpinLockLock(self.osSpinLock)
            
            print("Pass")
            
            OSSpinLockUnlock(self.osSpinLock)
            
        }
    }
    
    /// pthread_mutex
    /// http://blog.chinaunix.net/uid-26885237-id-3207962.html
    func pthreadMutexTest()
    {
        DispatchQueue.global().async {
            
            pthread_mutex_lock(self.pthreadMutex)
            for a in 0...3
            {
//                pthread_mutex_lock(self.pthreadMutex)
                self.test {
                    if a == 1 {
                        pthread_mutex_unlock(self.pthreadMutex)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            
            pthread_mutex_lock(self.pthreadMutex)
            
            print("Pass")
            
            pthread_mutex_unlock(self.pthreadMutex)
        }
    }
    
    
    /// pthread_rwlock 读写锁
    /// 当读写锁被一个线程以读模式占用的时候，写操作的其他线程会被阻塞，读操作的其他线程还可以继续进行。
    /// 当读写锁被一个线程以写模式占用的时候，写操作的其他线程会被阻塞，读操作的其他线程也被阻塞。
    func pthreadRWLockTestA()
    {
        // Reading
        DispatchQueue.global().async {
            pthread_rwlock_rdlock(self.pthreadRWLock)
            for _ in 0...5 {
                print("reading_0...")
                sleep(1)
            }
            pthread_rwlock_unlock(self.pthreadRWLock)
        }
        
        //write
        DispatchQueue.main.async {
            pthread_rwlock_wrlock(self.pthreadRWLock)
            for _ in 0...5 {
                print("writing...")
                sleep(1)
            }
            pthread_rwlock_unlock(self.pthreadRWLock)
        }
        
        //Reading
        self.testQueue.async {
            pthread_rwlock_rdlock(self.pthreadRWLock)
            
            for _ in 0...5 {
                print("reading_1...")
                sleep(1)
            }
            
            pthread_rwlock_unlock(self.pthreadRWLock)
        }
    }
    
    func pthreadRWLockTestB()
    {
        // Reading
        DispatchQueue.global().async {
            pthread_rwlock_wrlock(self.pthreadRWLock)
            for _ in 0...5 {
                print("writing_0...")
                sleep(1)
            }
            pthread_rwlock_unlock(self.pthreadRWLock)
        }
        
        //write
        DispatchQueue.main.async {
            pthread_rwlock_wrlock(self.pthreadRWLock)
            for _ in 0...5 {
                print("writing_1...")
                sleep(1)
            }
            pthread_rwlock_unlock(self.pthreadRWLock)
        }
        
        //Reading
        self.testQueue.async {
            pthread_rwlock_rdlock(self.pthreadRWLock)
            
            for _ in 0...5 {
                print("reading...")
                sleep(1)
            }
            
            pthread_rwlock_unlock(self.pthreadRWLock)
        }
    }
    
    deinit {
        pthread_mutex_destroy(self.pthreadMutex)
        pthread_rwlock_destroy(self.pthreadRWLock)
    }
}


extension ViewController
{
    func test(_ result:(() -> Void))
    {
        sleep(1)
        self.i = self.i + 1
        print("\(#function):\(self.i)")
        result()
    }
}




