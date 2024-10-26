import hashlib

def sha256_packed(input_data):
    sha = hashlib.sha256()
    sha.update(input_data)
    return sha.hexdigest()

# Example cards: [rank, suit]
hole_card_1 = [1, 2]  # Replace with actual card values
hole_card_2 = [3, 4]  # Replace with actual card values

# Create packed input data
input0 = bytes(hole_card_1 + [0, 0])
input1 = bytes(hole_card_2 + [0, 0])

# Compute hashes
hash0 = sha256_packed(input0)
hash1 = sha256_packed(input1)

print(f"Hash 0: {hash0}")
print(f"Hash 1: {hash1}")

def split_hash_to_fields(hash_hex):
    hash_int = int(hash_hex, 16)
    high = hash_int >> 128
    low = hash_int & ((1 << 128) - 1)
    return high, low

hash0_high, hash0_low = split_hash_to_fields(hash0)
hash1_high, hash1_low = split_hash_to_fields(hash1)

print(f"Hash 0 High: {hash0_high}")
print(f"Hash 0 Low: {hash0_low}")
print(f"Hash 1 High: {hash1_high}")
print(f"Hash 1 Low: {hash1_low}")
