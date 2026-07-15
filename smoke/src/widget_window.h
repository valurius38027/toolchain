#pragma once

#include <QWidget>

class WidgetWindow final : public QWidget
{
    Q_OBJECT

public:
    explicit WidgetWindow(QWidget *parent = nullptr);
};
