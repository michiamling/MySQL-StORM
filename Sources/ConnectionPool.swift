//
//  ConnectionPool.swift
//  MySQL
//
//  Created by ito on 12/24/15.
//  Copyright © 2015 Yusuke Ito. All rights reserved. Adapted by Michael Amling
//

import Dispatch

#if os(Linux)
    import Glibc
#endif

import StORM
import MySQL

final public class ConnectionPool: CustomStringConvertible {
    
    
    public var initialConnections: Int = 1 {
        didSet {
            while pool.count < initialConnections {
                _ = preparedNewConnection()
            }
        }
    }
    public var maxConnections: Int = 10
    
    internal var pool: [MySQLConnect] = []
    private var mutex = DispatchQueue(label: "conpoolqueue", attributes: [])
    
    private static var libraryInitialized: Bool = false
    
    public var options: StORMDataSourceCredentials?

    public init() { }
    
    
    public func setOptions(options: StORMDataSourceCredentials){
        self.options = options
        
        /*if type(of: self).libraryInitialized == false && mysql_server_init(0, nil, nil) != 0 { // mysql_library_init
         fatalError("could not initialize MySQL library")
         }
         type(of: self).libraryInitialized = true
         
         */
        mutex.sync {
            if pool.count < initialConnections {
                for _ in 0..<initialConnections {
                    _ = preparedNewConnection()
                }
            }
        }
    }
    
    
    
    open class var sharedPoolInstance: ConnectionPool {
        struct Singleton {
            public static let instance = ConnectionPool()
        }
                
        return Singleton.instance
    }
    
    private func preparedNewConnection() -> MySQLConnect {
        let thisConnection = MySQLConnect(
            host:		(options?.host)!,
            username:	(options?.username)!,
            password:	(options?.password)!,
            database:	MySQLConnector.database,
            port:		MySQLConnector.port
        )
        thisConnection.open()
        pool.append(thisConnection)
        return thisConnection
    }
    
    //private let poolSemaphore = DispatchSemaphore(value: 1)
    
    private func getUsableConnection() -> MySQLConnect? {
                
        for (index, c) in pool.enumerated().reversed() {
            if c.isInUse == false && c.ping() == true {
                c.isInUse = true
                return c
            }
            
            if c.isInUse == false && c.ping() == false {
                print("broken")
                pool.remove(at: index)
            }
            
        }
        return nil
    }
    
    public var timeoutForGetConnection: Int = 60
    
    internal func getConnection() throws -> MySQLConnect? {
        var connection: MySQLConnect? =
        mutex.sync {
            if let conn = getUsableConnection() {
                return conn
            }
            if pool.count < maxConnections {
                let conn = preparedNewConnection()
                conn.isInUse = true
                return conn
            }
            return nil
        }
        
        if let conn = connection {
            return conn
        }
        
        let tickInMs = 50 // ms
        var timeOutCount = (timeoutForGetConnection*1000)/tickInMs
        while timeOutCount > 0 {
            usleep(useconds_t(1000*tickInMs))
            connection = mutex.sync {
                getUsableConnection()
            }
            if connection != nil {
                break
            }
            timeOutCount -= 1
        }
        
        guard let conn = connection else {
            //LogFile.error("MySQL connection pool error")
            print("MySQL connection pool error")
            //resultCode = .error("MySQL connection pool error")
            return nil
        }
        return conn
    }
    
    internal func releaseConnection(_ conn: MySQLConnect) {
        mutex.sync {
            conn.isInUse = false
            //poolSemaphore.signal()
        }
    }
    
    internal var inUseConnections: Int {
        return mutex.sync {
            var count: Int = 0
            for c in pool {
                if c.isInUse {
                    count += 1
                }
            }
            return count
            } as Int
    }
    
    public var description: String {
        return "initial: \(initialConnections), max: \(maxConnections), in use: \(inUseConnections)"
    }
}


extension ConnectionPool {
    
    public func execute<T>( _ block: (_ conn: MySQLConnect) throws -> T  ) throws -> T? {
        if let conn = try getConnection() {
        
            defer {
                releaseConnection(conn)
            }
            return try block(conn)
        }
        
        return nil
    }
    
}
