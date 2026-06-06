# Modules prepared for Mimic mocking (used by the gRPC/streaming unit tests
# to avoid opening live connections).
Mimic.copy(ExWebull.Grpc.Client)
Mimic.copy(Tortoise311.Connection)

ExUnit.start()
