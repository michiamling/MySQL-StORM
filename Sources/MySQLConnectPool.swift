//
//  MySQLConnect.swift
//  MySQLStORM
//
//  Created by Jonathan Guthrie on 2016-09-23.
//
//

import StORM
import MySQL
import PerfectLogger
import Dispatch

public struct MySQLServerConnectionItem {
    public var server = MySQL()
    public var isUse = false
}

/// Base connector class, inheriting from StORMConnect.
/// Provides connection services for the Database Provider
open class MySQLConnectionPool {

    open class var sharedPoolInstance: MySQLConnectionPool {
        struct Singleton {
            public static let instance = MySQLConnectionPool()
        }
        return Singleton.instance
    }
    
    public var serverPool : [MySQLConnect] = []
    let serverMySQLQueue = DispatchQueue(label: "MySQLPoolQueue", attributes: .concurrent)
    
    var host : String = ""
    var username : String = ""
    var password : String = ""
    var database : String = ""
    var port : Int = 0
    
    
    public init() {
        
    }

	/// Init with credentials
    public func initWithHost(host: String,
                username: String,
                password: String,
                database: String,
                port: Int){
        
        self.host = host
        self.username = username
        self.password = password
        self.database = database
        self.port = port
       
	}
    


    
    public var maxConnections: Int = 10

    
    private func preparedNewConnection() -> MySQLConnect {

        
        let thisConnection = MySQLConnect(
            host:		self.host,
            username:	self.username,
            password:	self.password,
            database:	self.database,
            port:		self.port
        )
        
        thisConnection.open()
        
        serverPool.append(thisConnection)
        return thisConnection
    }
    
    private func getUsableConnection() -> MySQLConnect? {
        for c in serverPool {
            if c.isInUse == false /*&& c.ping*/ {
                c.isInUse = true
                return c
            }
        }
        return nil
    }
    
    public func getConnection() -> MySQLConnect {
        let connection: MySQLConnect? =
            serverMySQLQueue.sync {
                if let conn = getUsableConnection() {
                    return conn
                }
                if serverPool.count < maxConnections {
                    let conn = preparedNewConnection()
                    conn.isInUse = true
                    return conn
                }
                return nil
        }
        if let conn = connection {
            return conn
        }
        
        let conn = preparedNewConnection()
        conn.isInUse = true
        return conn
        
    }
    
    public func releaseConnection(_ connection: MySQLConnect) {
        serverMySQLQueue.sync {
            connection.isInUse = false
            //poolSemaphore.signal()
        }
    }
    
}


