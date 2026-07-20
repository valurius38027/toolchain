#include <QCoreApplication>
#include <QString>
#include <flatbuffers/flatbuffers.h>
#include <gtest/gtest.h>
#include <hb.h>
#include <vulkan/vulkan.h>
#include <rhi/qrhi.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#include <cstdint>
#include <iostream>

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
    FT_Done_FreeType(freetype);

    hb_buffer_t* harfbuzzBuffer = hb_buffer_create();
    if (harfbuzzBuffer == nullptr || !hb_buffer_allocation_successful(harfbuzzBuffer)) {
        std::cerr << "HarfBuzz failed to create a buffer\n";
        if (harfbuzzBuffer != nullptr) {
            hb_buffer_destroy(harfbuzzBuffer);
        }
        return 15;
    }
    hb_buffer_add_utf8(harfbuzzBuffer, "UltraRender", -1, 0, -1);
    hb_buffer_guess_segment_properties(harfbuzzBuffer);
    hb_buffer_destroy(harfbuzzBuffer);

    flatbuffers::FlatBufferBuilder builder;
    if (builder.GetSize() != 0) {
        std::cerr << "FlatBuffers builder has an invalid initial state\n";
        return 16;
    }

    std::cout << "Qt=" << qVersion()
              << " Vulkan=" << VK_VERSION_MAJOR(instanceVersion) << '.'
              << VK_VERSION_MINOR(instanceVersion) << '.'
              << VK_VERSION_PATCH(instanceVersion) << '\n';
    return 0;
}
