//
//  HRVConnectivityPracTests.swift
//  HRVConnectivityPracTests
//
//  Created by Austin Harrison on 2/3/25.
//

import XCTest
import CoreData
@testable import HRVConnectivityPrac

class HRVDataTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // Create an in-memory store so we don't write to disk.
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        persistenceController = nil
        context = nil
        super.tearDown()
    }
    
    func testSavingAndFetchingHRVData() {
        // Create a test HRVData record using the convenience initializer from your extension.
        let testHeartBeats: [Double] = [800.0, 810.0, 790.0]
        let testHRV = HRVData(
            context: context,
            sdnn: 40.0,
            rmssd: 35.0,
            pnn50: 20.0,
            heartBeats: testHeartBeats,
            creationDate: Date()
        )
        
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save HRVData: \(error)")
        }
        
        // Fetch HRVData records.
        let fetchRequest: NSFetchRequest<HRVData> = HRVData.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "There should be exactly one HRVData record saved.")
            if let fetchedData = results.first {
                XCTAssertEqual(fetchedData.sdnn, 40.0, "SDNN should be 40.0")
                XCTAssertEqual(fetchedData.rmssd, 35.0, "RMSSD should be 35.0")
                XCTAssertEqual(fetchedData.pnn50, 20.0, "PNN50 should be 20.0")
                // Convert heartBeats back to [Double]
                if let beats = fetchedData.heartBeats as? [Double] {
                    XCTAssertEqual(beats, testHeartBeats, "HeartBeats array should match the test data.")
                } else {
                    XCTFail("Failed to convert heartBeats to [Double]")
                }
            }
        } catch {
            XCTFail("Error fetching HRVData: \(error)")
        }
    }
}
