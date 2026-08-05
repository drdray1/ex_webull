# Modules prepared for Mimic mocking (used by the streaming unit tests to
# avoid opening live connections).
Mimic.copy(Tortoise311.Connection)
Mimic.copy(GRPC.Stub)
Mimic.copy(ExWebull.Proto.Events.EventService.Stub)

ExUnit.start()
