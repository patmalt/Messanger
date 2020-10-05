# Messanger

This is an example app of end-to-end encryption with CloudKit and Core Data.

A Curve25519 Private Key is generated and stored in the user's private iCloud database. This enables the private key to be shared between one user's devices but keeps them safe from the public.

Public keys and Messages are stored in the public iCloud database. This allows all users to select a key to be the recipient of a message. Once the user has entered their message, the contents of the message are encrypted with the user's private key and the public key the user selected. The encrypted message is saved with the ID of the public key in which it was encrypted. This will allow the holder of assoicated private key of the selected public key to read the message.

[Persistence.swift](https://github.com/patmalt/Messanger/blob/main/Messanger/Persistence/Persistence.swift#L47) Implements the public and private CloudKit Core Data stores.
[Crypto.swift](https://github.com/patmalt/Messanger/blob/main/Messanger/Crypto/Crypto.swift) Implements the encryption and decryption logic
[KeychainModel.swift](https://github.com/patmalt/Messanger/blob/main/Messanger/Application/KeychainModel.swift) Implements the creation of keys
