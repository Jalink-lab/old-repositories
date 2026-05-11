"""simple program to find the device that tensorflow uses"""
from tensorflow.python.client import device_lib
print(device_lib.list_local_devices())
'''
>>> output for Rolfs PC >>>
[name: "/device:CPU:0"
device_type: "CPU"
memory_limit: 268435456
locality {
}
incarnation: 11104337854381602718
, name: "/device:GPU:0"
device_type: "GPU"
memory_limit: 1422504755
locality {
  bus_id: 1
  links {
  }
}
incarnation: 11084693604614574445
physical_device_desc: "device: 0, name: GeForce GTX 960, pci bus id: 0000:01:00.0, compute capability: 5.2"
]

Process finished with exit code 0
'''