# BAPromise 

[![Coverage Status](https://coveralls.io/repos/github/benski/BAPromise/badge.svg?branch=master)](https://coveralls.io/github/benski/BAPromise?branch=master)

## Objective C Promise Library ##

This is a promise library for Objective C. It is a lightweight library and does not bring in any additional dependencies and adds very little complexity.

### What are promises?

If you are not familiar with promises, the easiest way to think of them is as a managed object for completion/failure blocks. Instead of passing in a completion and failure block, an API can return a promise to which you attach the blocks. The promise object can have multiple completion blocks assigned, can be canceled, and can be transformed into another promise via a block.


### Examples
These examples are concerned with how to use the APIs that return promises. Creating promise objects is not covered here, for simplicity. 


As a replacement for completion failure blocks:

```objc
	BAPromise *promise = [someObject methodThatReturnsPromise]; 
	[[promise done:^(id successObject) { 
	    self.textLabel = (NSString *)successObject; 
	} rejected:^(NSError *error) { 
	    self.textLabel = error.localizedDescription; 
	}];
```

You typically know what is passed in the completion block, so the following is more readable: 

```objc 
      BAPromise *promise = [someObject methodThatReturnsPromise]; 
      [[promise done:^(NSString *successObject) { 
        self.textLabel = successObject; 
      } rejected:^(NSError *error) { 
        self.textLabel = error.localizedDescription; 
      }];
```

### Templating
Promise objects can be optionally templated with the completion block parameter, using features new to XCode 7. This makes it a syntax error to have the wrong block parameter, and also makes autocompletion work as expected. The above example would instead be as follows. 

```objc
	BAPromise<NSString *> *promise = [someObject methodThatReturnsPromise]; 
	[[promise done:^(NSString *successObject) { 
	   self.textLabel = (NSString *)successObject; } 
        rejected:^(NSError *error) { 
           self.textLabel = error.localizedDescription; 
        }];
```

### Cancellation
Promises can be canceled. The rules for promise cancelation are as follows: 

1. When you cancel a promise, it is guaranteed that neither your completion nor failure block are called. The promise's reference to your blocks will also be removed. 
2. Promises must be canceled on the same queue as where the done callback completes. See the section on threading for more information. 
3. Most of the time, you should cancel the CancelToken returned from the 'done' method call (block attachment method). 
4. Calling cancel on the promise object itself will call the failure block for all attached blocks 
5. The underlying operation may or may not be canceled, depending on the implementation of the code that creating the original promise.

### Promise chaining 
A common idiom with completion block APIs is implementing a method that accepts a completion/failure block and in turn calling another API that takes a completion/failure block. This is implemented in the promise library via a method called 'then'. A simple example.

```objc 
- (BAPromise<CustomObject *> *)promiseForCustomObject { 
      BAPromise<NSDictionary *> *promise = [someObject promiseForJSON]; 
      return [promise then:^id(NSDictionary *dictionary) { 
	 CustomObject *object = [[CustomObject alloc] initWithDictionary:dictionary]; return object; 
      }]; 
 }
```

A few things of note: 

1. Due to limitations in XCode 7 generics, it is not possible to autocomplete the parametize the promise returned from 'then' 
2. If the failure ('rejected') block is not defined, a default implementation is provided that will chain the rejection failure 
3. Returning `NSError` from the 'then' block (or a non-NSError object from the 'rejected' block) will convert a failure to a success or vice-versa


### Installation

Xcode 6
```ruby
pod "BAPromise", "~> 1.0"
```

Xcode 7
```ruby
pod "BAPromise", "~> 1.1"
```

