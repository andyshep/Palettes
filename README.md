Palettes
====

Palettes is an iOS app for viewing color palettes from the [COLOURlovers API](http://www.colourlovers.com/api).

### Features

Palettes contains three Incremental Store subclasses for loading model data from various sources, including a local JSON file and a remote web resource. These stores are uses as examples. To switch between the store types, modify `storeType` within the `NSPersistentStoreCoordinator` declaration of `CoreDataManager.swift`.

<br>

![palettes.png](http://i.imgur.com/RG98ln8.png)