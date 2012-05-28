//
//  PHFDelegateChainTest.m
//  PHFDelegateChainTest
//
//  Created by Philipe Fatio on 28.05.12.
//  Copyright (c) 2012 loqize.me. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMock.h>
#import "PHFDelegateChain.h"

#pragma mark - Test Helpers

@protocol Receiver <NSObject>
@required
- (void)requiredMethod;
@optional
- (void)optionalMethod;
- (NSString *)returningMethod;
@end

@interface TestReceiverOnlyRequired : NSObject <Receiver> @end
@implementation TestReceiverOnlyRequired
- (void)requiredMethod {}
@end

@interface TestReceiverRequiredAndOptional : NSObject <Receiver> @end
@implementation TestReceiverRequiredAndOptional
- (void)requiredMethod {}
- (void)optionalMethod {}
- (NSString *)returningMethod { return nil; }
@end

#pragma mark - Test Case

@interface PHFDelegateChainTest : SenTestCase @end

@implementation PHFDelegateChainTest

- (void)testRequiredMethodShouldBeInvokedOnAllObjects {
    id firstObject  = [OCMockObject mockForClass:[TestReceiverOnlyRequired class]];
    id secondObject = [OCMockObject mockForClass:[TestReceiverRequiredAndOptional class]];
    PHFDelegateChain<Receiver> *chain = [PHFDelegateChain delegateChainWithObjects:firstObject, secondObject, nil];

    [[firstObject  expect] requiredMethod];
    [[secondObject expect] requiredMethod];
    [chain requiredMethod];
    [firstObject  verify];
    [secondObject verify];
}

- (void)testOptionalMethodShouldBeInvokedOnlyOnObjectsImplementingIt {
    id firstObject  = [OCMockObject mockForClass:[TestReceiverOnlyRequired class]];
    id secondObject = [OCMockObject mockForClass:[TestReceiverRequiredAndOptional class]];
    PHFDelegateChain<Receiver> *chain = [PHFDelegateChain delegateChainWithObjects:firstObject, secondObject, nil];

    [[firstObject  reject] optionalMethod];
    [[secondObject expect] optionalMethod];
    [chain optionalMethod];
    [firstObject  verify];
    [secondObject verify];
}

- (void)testWhenChainIsBreakingMethodShouldOnlyBeInvokedOnFirstRespondingObject {
    id firstObject  = [OCMockObject mockForClass:[TestReceiverOnlyRequired class]];
    id secondObject = [OCMockObject mockForClass:[TestReceiverRequiredAndOptional class]];
    PHFDelegateChain<Receiver> *chain = [PHFDelegateChain delegateChainWithObjects:firstObject, secondObject, nil];
    [chain __setBreaking:YES];

    [[firstObject  expect] requiredMethod];
    [[secondObject reject] requiredMethod];
    [chain requiredMethod];
    [firstObject  verify];
    [secondObject verify];
}

- (void)testReturningMethodShouldOnlyBeInvokedOnFirstRespondingObject {
    id firstObject  = [OCMockObject mockForClass:[TestReceiverRequiredAndOptional class]];
    id secondObject = [OCMockObject mockForClass:[TestReceiverOnlyRequired class]];
    PHFDelegateChain<Receiver> *chain = [PHFDelegateChain delegateChainWithObjects:firstObject, secondObject, nil];

    [[[firstObject expect] andReturn:@"Foo"] returningMethod];
    [[secondObject reject] returningMethod];
    NSString *response = [chain returningMethod];
    STAssertTrue([response isEqualToString:@"Foo"], nil);
    [firstObject  verify];
    [secondObject verify];
}

- (void)testShouldConformToProtocolIfAnyObjectDoes {
    PHFDelegateChain *chain = [PHFDelegateChain delegateChainWithObjects:[TestReceiverOnlyRequired new], nil];
    STAssertTrue([chain conformsToProtocol:@protocol(Receiver)], nil);
}

- (void)testShouldNotConformToProtocolIfNoObjectDoes {
    PHFDelegateChain *chain = [PHFDelegateChain delegateChainWithObjects:[NSObject new], nil];
    STAssertFalse([chain conformsToProtocol:@protocol(Receiver)], nil);
}

- (void)testShouldRespondToMethodIfAnyObjectDoes {
    PHFDelegateChain *chain = [PHFDelegateChain delegateChainWithObjects:[TestReceiverOnlyRequired new], [TestReceiverRequiredAndOptional new], nil];
    STAssertTrue([chain respondsToSelector:@selector(optionalMethod)], nil);
}

- (void)testShouldNotRespondToMethodIfNoObjectDoes {
    PHFDelegateChain *chain = [PHFDelegateChain delegateChainWithObjects:[TestReceiverOnlyRequired new], nil];
    STAssertFalse([chain respondsToSelector:@selector(optionalMethod)], nil);
}

- (void)testShouldAllowManipulationOfObjects {
    id firstObject  = [OCMockObject mockForClass:[TestReceiverOnlyRequired class]];
    id secondObject = [OCMockObject mockForClass:[TestReceiverRequiredAndOptional class]];
    PHFDelegateChain<Receiver> *chain = [PHFDelegateChain delegateChainWithObjects:firstObject, nil];

    [[firstObject  expect] requiredMethod];
    [chain requiredMethod];
    [firstObject  verify];

    [[chain __objects] addObject:secondObject];
    [[firstObject  expect] requiredMethod];
    [[secondObject expect] requiredMethod];
    [chain requiredMethod];
    [firstObject  verify];
    [secondObject verify];
}

- (void)testShouldRaiseWhenPerformingMethodThatNoObjectRespondsTo {
    PHFDelegateChain<Receiver> *chain = [PHFDelegateChain delegateChainWithObjects:[TestReceiverOnlyRequired new], nil];
    STAssertThrowsSpecificNamed([chain performSelector:@selector(optionalMethod)], NSException, NSInvalidArgumentException, nil);
}

@end
