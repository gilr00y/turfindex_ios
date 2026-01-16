# Package.swift Requirements

Add the Supabase Swift package to your Xcode project:

## Via Xcode:
1. File → Add Package Dependencies
2. Enter: https://github.com/supabase/supabase-swift
3. Select "Up to Next Major Version" with the latest version

## Required Imports in Files:

### SupabaseConfig.swift
```swift
import Supabase
```

### AuthService.swift
```swift
import Supabase
import Auth
```

### PostService.swift
```swift
import Supabase
```

### StorageService.swift (for S3 signing)
```swift
import CommonCrypto
```

**Note:** CommonCrypto requires a bridging header in your project. Add this to your bridging header:

```objective-c
#import <CommonCrypto/CommonCrypto.h>
```

Or create a module.modulemap:
```
module CommonCrypto [system] {
    header "/usr/include/CommonCrypto/CommonCrypto.h"
    export *
}
```
