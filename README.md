Palettes
====

Palettes contains three `NSIncrementalStore` subclasses for loading data from various sources, including a local JSON file and a remote API endpoint. These stores are intended to be used independantly as examples for using Incremental Stores with Core Data.

Palettes is setup to work with data from the from the [COLOURlovers API](http://www.colourlovers.com/api) but the stores are simple enough to be adapted for other data formats. The JSON modeling is not central to the implementation.

### Stores

[`LocalIncrementalStore`](https://github.com/andyshep/Palettes/blob/master/Palettes/LocalIncrementalStore.swift) provides the most basic building blocks and a disk based read-only Incremental Store.

[`RemoteIncrementalStore`](https://github.com/andyshep/Palettes/blob/master/Palettes/RemoteIncrementalStore.swift) uses an API to provide JSON from a remote data source. This class can be without a Fetched Results Controller, and leverage `NSAsynchronousFetchRequest` for basic asynchronous request handling.

[`CachingIncrementalStore`](https://github.com/andyshep/Palettes/blob/master/Palettes/CachingIncrementalStore.swift) utilizes a second internal Core Data stack to serve requests from local cache while asynchronously updating from a remote data source. As remote objects are fetched, the local cache context is updated in addition to the main context. Using an `NSFetchedResultsController` is recommended for observing and responding to change notifications.

For more information, see the complete write up about [Building an NSIncrementalStore](https://andyshep.org/2015/01/2015-01-10-building-basic-nsincrementalstore/).

### Default Setup

Palettes is setup to use the `CachingIncrementalStore` by default. To change stores, modify the `storeType` passed into the `NSPersistentStoreCoordinator`, as it's initialized inside [`CoreDataManager`](https://github.com/andyshep/Palettes/blob/master/Palettes/CoreDataManager.swift#L76).

## Requirements

* Xcode 10.2
* Swift 5
	
## License

The MIT License (MIT)

![palettes.png](http://i.imgur.com/StQwM9T.png)