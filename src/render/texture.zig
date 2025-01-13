const std = @import("std");
const zstbi = @import("zstbi");
const sg = @import("sokol").gfx;
const vec2 = @import("../vendor/math.zig").Vec2;

pub const SubTexture = struct {
    texture: *const Texture,
    width: i32,
    height: i32,
    uv_min: vec2,
    uv_max: vec2,
};

pub const Texture = struct {
    binding: sg.Image,
    width: i32,
    height: i32,

    pub fn setup(allocator: *std.mem.Allocator) !void {
        zstbi.init(allocator.*);
    }

    pub fn cleanup() void {
        zstbi.deinit();
    }

    pub fn init(data: []u8, width: i32, height: i32) Texture {
        const binding = sg.makeImage(.{
            .width = width,
            .height = height,
            .data = init: {
                var sgData = sg.ImageData{};
                sgData.subimage[0][0] = sg.asRange(data);
                break :init sgData;
            },
        });

        return Texture{
            .binding = binding,
            .width = width,
            .height = height,
        };
    }

    pub fn init32(data: []const u32, width: i32, height: i32) Texture {
        const binding = sg.makeImage(.{
            .width = width,
            .height = height,
            .data = init: {
                var sgData = sg.ImageData{};
                sgData.subimage[0][0] = sg.asRange(data);
                break :init sgData;
            },
        });

        return Texture{
            .binding = binding,
            .width = width,
            .height = height,
        };
    }

    pub fn initFromPath(path: [:0]const u8) !Texture {
        const info = zstbi.Image.info(path);
        var image = try zstbi.Image.loadFromFile(path, info.num_components);
        const width = @as(i32, @intCast(image.width));
        const height = @as(i32, @intCast(image.height));

        const texture = init(image.data, width, height);

        image.deinit();
        return texture;
    }

    pub fn deinit(self: *Texture) void {
        sg.destroyImage(self.binding);
    }

    pub fn getSubTexture(self: *const Texture, x: u32, y: u32, width: i32, height: i32) SubTexture {
        const _x = @as(f32, @floatFromInt(x));
        const _y = @as(f32, @floatFromInt(y));
        const _width = @as(f32, @floatFromInt(width));
        const _height = @as(f32, @floatFromInt(height));
        const total_width = @as(f32, @floatFromInt(self.width));
        const total_height = @as(f32, @floatFromInt(self.height));

        const uv_min = vec2.new(_x / total_width, _y / total_height);
        const uv_max = vec2.new((_x + _width) / total_width, (_y + _height) / total_height);

        return SubTexture{
            .texture = self,
            .width = width,
            .height = height,
            .uv_min = uv_min,
            .uv_max = uv_max,
        };
    }
};
