package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable

@Serializable
enum class Element(val displayName: String) {
    FIRE("Fire"),
    EARTH("Earth"),
    AIR("Air"),
    WATER("Water");

    val index: Int get() = ordinal
}

@Serializable
enum class Modality(val displayName: String) {
    CARDINAL("Cardinal"),
    FIXED("Fixed"),
    MUTABLE("Mutable"),
}
