//
//  PreyStoreManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 14/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import StoreKit

class PreyStoreManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    
    // MARK: Singleton
    
    static let sharedInstance   = PreyStoreManager()
    override private init() {
    }

    // MARK: Properties
    
    var purchasableObjects      = [SKProduct]()

    var productsRequest         :SKProductsRequest!
    
    var onTransactionCancelled  : [() -> Void] = []
    
    var onTransactionCompleted  : [(productId:String, receiptData:NSData) -> Void] = []
    
    var onRestoreFailed         : [(error:NSError) -> Void] = []
    
    var onRestoreCompleted      : [() -> Void] = []
    
    
    // MARK: Methods
    
    // Request Product Data
    func requestProductData() {
        
        var products = Set<String>()
        products.insert(subscription1Year)
    
        // Set productsRequest
        productsRequest             = SKProductsRequest(productIdentifiers:products)
        productsRequest.delegate    = self
        productsRequest.start()
        
        // Add Transaction Observer
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    // BuyFeature
    func buyFeature(featureId:String, onComplete:(productId:String, receiptData:NSData) -> Void, onCancelled:() -> Void) {
        
        guard SKPaymentQueue.canMakePayments() else {
            displayErrorAlert("Check your parental control settings and try again later".localized,
                              titleMessage:"In-App Purchasing disabled".localized)
            return
        }

        onTransactionCompleted.append(onComplete)
        onTransactionCancelled.append(onCancelled)
        

        for product in purchasableObjects {
            if product.productIdentifier == featureId {
                let payment     = SKPayment(product:product)
                SKPaymentQueue.defaultQueue().addPayment(payment)
            }
        }
    }
    
    
    // MARK: Transaction Methods
    
    // CompleteTransaction
    func completeTransaction(transaction:SKPaymentTransaction) {

        provideContent(transaction.payment.productIdentifier, forReceipt:NSData(contentsOfURL:NSBundle.mainBundle().appStoreReceiptURL!)!)

        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    // FailedTransaction
    func failedTransaction(transaction:SKPaymentTransaction) {
        print("Failed transaction: \(transaction.description)")
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)

        onTransactionCancelled.first!()
    }
    
    // RestoreTransaction
    func restoreTransaction(transaction:SKPaymentTransaction) {
        
        provideContent(transaction.originalTransaction!.payment.productIdentifier,
                       forReceipt:NSData(contentsOfURL:NSBundle.mainBundle().appStoreReceiptURL!)!)

        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    // ProvideContent
    func provideContent(productIdentifier:String, forReceipt data:NSData) {

        let product = PreyStoreProduct(initWithProductId:productIdentifier, receiptData:data)

        // Verify receipt
        product.verifyReceiptOnComplete({() in
            // Success
            self.savePurchaseOfProduct(productIdentifier, withReceipt:data)
            self.onTransactionCompleted.first?(productId:productIdentifier, receiptData:data)
            }, onError:{() in
            // Error
            self.onTransactionCancelled.first?()
        })
    }
    
    // Save purchase
    func savePurchaseOfProduct(productIdentifier:String, withReceipt data:NSData) {
     
        FIXME()
        // WIP  save purchase
    }
    
    
    // MARK: SKPaymentTransactinObserver
    
    // UpdteTransactions
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("updatedTransactions SKPaymentQueue")
        
        for transaction in transactions {
            switch transaction.transactionState {

            case .Purchasing :
                print("Purchasing")

            case .Purchased :
                print("Purchased")
                completeTransaction(transaction)

            case .Failed :
                print("Failed")
                failedTransaction(transaction)
            
            case .Restored :
                print("Restored")
                restoreTransaction(transaction)
            
            case .Deferred :
                print("Deferred")
            }
        }
    }
 
    // restoreCompletedTransactionsFailedWithError
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        print("restoreCompletedTransactionsFailedWithError SKPaymentQueue")
        
        onRestoreFailed.first?(error:error)
        onRestoreFailed.removeAll()
    }
    
    // restoreCompletedTransactions
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("paymentQueueRestoreCompletedTransactionsFinished SKPaymentQueue")
        
        onRestoreCompleted.first?()
        onRestoreCompleted.removeAll()
    }
    
    // removedTransactions
    func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("removedTransactions SKPaymentQueue")
    }
    
    // MARK: SKProductsRequest
    
    // DidReceiveResponse
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("DidReceiveResponse SKProductsRequest")
        
        // Add object to purchableObjects from response
        purchasableObjects = response.products
        
        #if DEBUG
            for product in purchasableObjects {
                print("Feature: \(product.localizedTitle), Cost: \(product.price.doubleValue)")
            }
        #endif
        
        // Reset productsRequest
        productsRequest = nil
    }
    
    // RequestDidFinish
    func requestDidFinish(request: SKRequest) {
        print("RequestDidFinish SKProductsRequest")
    }
    
    // DidFailWithError
    func request(request: SKRequest, didFailWithError error: NSError) {
        print("DidFailWithError SKProductRequest: \(error.description)")
        productsRequest = nil
    }
}