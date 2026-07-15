#include "widget_window.h"

#include <QLabel>
#include <QVBoxLayout>

WidgetWindow::WidgetWindow(QWidget *parent)
    : QWidget(parent)
{
    setWindowTitle(QStringLiteral("Qt 6 Toolchain Smoke Test"));
    resize(480, 240);

    auto *layout = new QVBoxLayout(this);
    auto *label = new QLabel(QStringLiteral("Qt Widgets, QML and Quick 3D toolchain is operational."), this);
    label->setAlignment(Qt::AlignCenter);
    layout->addWidget(label);
}
