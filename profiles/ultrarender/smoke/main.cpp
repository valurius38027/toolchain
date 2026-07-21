#include <QCoreApplication>
#include <QString>
#include <flatbuffers/flatbuffers.h>
#include <gtest/gtest.h>
#include <hb-ft.h>
#include <hb.h>
#include <vulkan/vulkan.h>
#include <rhi/qrhi.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#include <cstdint>
#include <iostream>

namespace {
constexpr const char* kFontPath = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
}

int main(int argc, char** argv)
{
    QCoreApplication application(argc, argv);
    if (!QString::fromLatin1(qVersion()).startsWith(QStringLiteral("6."))) {
        std::cerr << "Qt 6 was not loaded\n";
        return 10;
    }

    QRhi* rhiCompileProbe = nullptr;
    if (rhiCompileProbe != nullptr) {
        return 11;
    }

    std::uint32_t instanceVersion = 0;
    if (vkEnumerateInstanceVersion(&instanceVersion) != VK_SUCCESS || instanceVersion == 0) {
        std::cerr << "Vulkan loader did not report an instance version\n";
        return 12;
    }

    ::testing::InitGoogleTest(&argc, argv);
    if (::testing::UnitTest::GetInstance() == nullptr) {
        std::cerr << "GTest failed to initialize\n";
        return 13;
    }

    FT_Library freetype = nullptr;
    if (FT_Init_FreeType(&freetype) != 0 || freetype == nullptr) {
        std::cerr << "FreeType failed to initialize\n";
        return 14;
    }

    FT_Face face = nullptr;
    if (FT_New_Face(freetype, kFontPath, 0, &face) != 0 || face == nullptr) {
        std::cerr << "FreeType failed to load deterministic DejaVu Sans\n";
        FT_Done_FreeType(freetype);
        return 15;
    }
    if (FT_Set_Pixel_Sizes(face, 0, 16) != 0) {
        std::cerr << "FreeType failed to configure the font size\n";
        FT_Done_Face(face);
        FT_Done_FreeType(freetype);
        return 16;
    }

    hb_font_t* harfbuzzFont = hb_ft_font_create_referenced(face);
    hb_buffer_t* harfbuzzBuffer = hb_buffer_create();
    if (harfbuzzFont == nullptr || harfbuzzBuffer == nullptr ||
        !hb_buffer_allocation_successful(harfbuzzBuffer)) {
        std::cerr << "HarfBuzz failed to create font or buffer\n";
        if (harfbuzzBuffer != nullptr) {
            hb_buffer_destroy(harfbuzzBuffer);
        }
        if (harfbuzzFont != nullptr) {
            hb_font_destroy(harfbuzzFont);
        }
        FT_Done_Face(face);
        FT_Done_FreeType(freetype);
        return 17;
    }

    constexpr char kProbeText[] = "UltraRender Ω";
    hb_buffer_add_utf8(harfbuzzBuffer, kProbeText, -1, 0, -1);
    hb_buffer_guess_segment_properties(harfbuzzBuffer);
    hb_shape(harfbuzzFont, harfbuzzBuffer, nullptr, 0);

    unsigned int glyphCount = 0;
    const hb_glyph_position_t* positions =
        hb_buffer_get_glyph_positions(harfbuzzBuffer, &glyphCount);
    std::int64_t totalAdvance = 0;
    for (unsigned int index = 0; index < glyphCount; ++index) {
        totalAdvance += positions[index].x_advance;
    }
    if (glyphCount == 0 || positions == nullptr || totalAdvance <= 0) {
        std::cerr << "HarfBuzz did not produce shaped glyphs with positive advance\n";
        hb_buffer_destroy(harfbuzzBuffer);
        hb_font_destroy(harfbuzzFont);
        FT_Done_Face(face);
        FT_Done_FreeType(freetype);
        return 18;
    }

    hb_buffer_destroy(harfbuzzBuffer);
    hb_font_destroy(harfbuzzFont);
    FT_Done_Face(face);
    FT_Done_FreeType(freetype);

    flatbuffers::FlatBufferBuilder builder;
    if (builder.GetSize() != 0) {
        std::cerr << "FlatBuffers builder has an invalid initial state\n";
        return 19;
    }

    std::cout << "Qt=" << qVersion()
              << " Vulkan=" << VK_VERSION_MAJOR(instanceVersion) << '.'
              << VK_VERSION_MINOR(instanceVersion) << '.'
              << VK_VERSION_PATCH(instanceVersion)
              << " Font=DejaVuSans Glyphs=" << glyphCount
              << " Advance26_6=" << totalAdvance << '\n';
    return 0;
}
