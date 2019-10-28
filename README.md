# Find Cat Breed

<img align="left" width="128" height="128" src="docs/img/app_icon.png">
Find Cat Breed is an iOS 13+ app which let you find the breed of a cat by pointing your device camera on it.

[<img width="180" src="docs/img/app_store.png">](https://apps.apple.com/us/app/find-cat-breed/id1484880085)

## App demonstration

![App video](docs/img/app_demo.gif)

## How does it work?

Find Cat Breed is a computer vision application that uses on-device machine learning to identify the breed of a cat on a photo. A ResNet classifier bundled in a CoreML is capable of differentiating 44 different cat breeds with a 51% accuracy.

To get best results, several tips have been used such as training with data augmentation. Also for better stability, the app takes several photos a in short time frame and automatically aggregates related classfier predictions.
