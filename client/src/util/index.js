export function displayAddress(address = '') {
  return address?.slice(0, 4) + '...' + address?.slice(-8);
}
