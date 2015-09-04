/*
 * FireControlNode.cpp
 *
 *  Created on: 4 Sep 2015
 *      Author: gdp24
 */

#include "FireControlNode.h"

#include <maya/MPlug.h>
#include <maya/MDataBlock.h>
#include <maya/MDataHandle.h>
#include <maya/MGlobal.h>
#include <maya/MFnTypedAttribute.h>
#include <maya/MFnNurbsSurfaceData.h>
#include <maya/MFnNurbsSurface.h>
#include <maya/MPointArray.h>
#include <maya/MAngle.h>
#include <maya/MItGeometry.h>
#include <maya/MMatrix.h>
#include <maya/MFnStringData.h>
#include <maya/MFnEnumAttribute.h>
#include <assert.h>
#include <float.h>

const MTypeId FireControlNode::id(0x00344);

MObject FireControlNode::density_file;
MObject FireControlNode::density_file_first;
MObject FireControlNode::density_scale;
MObject FireControlNode::density_offset;
MObject FireControlNode::density_read_mode;
MObject FireControlNode::temperature_file;
MObject FireControlNode::temperature_file_first;
MObject FireControlNode::temperature_scale;
MObject FireControlNode::temperature_offset;
MObject FireControlNode::temperature_read_mode;
MObject FireControlNode::interpolation_mode;
MObject FireControlNode::fuel_type;
MObject FireControlNode::visual_adaptation_factor;
MObject FireControlNode::intensity;
MObject FireControlNode::shadow_threshold;
MObject FireControlNode::decay;
MObject FireControlNode::march_increment;
MObject FireControlNode::cast_shadows;
MObject FireControlNode::high_samples;

// Outputs
MObject FireControlNode::density_file_out;
MObject FireControlNode::density_scale_out;
MObject FireControlNode::density_offset_out;
MObject FireControlNode::density_read_mode_out;
MObject FireControlNode::temperature_file_out;
MObject FireControlNode::temperature_scale_out;
MObject FireControlNode::temperature_offset_out;
MObject FireControlNode::temperature_read_mode_out;
MObject FireControlNode::interpolation_mode_out;
MObject FireControlNode::fuel_type_out;
MObject FireControlNode::visual_adaptation_factor_out;
MObject FireControlNode::intensity_out;
MObject FireControlNode::shadow_threshold_out;
MObject FireControlNode::decay_out;
MObject FireControlNode::march_increment_out;
MObject FireControlNode::cast_shadows_out;
MObject FireControlNode::high_samples_out;

MStatus FireControlNode::compute(const MPlug& plug, MDataBlock& data) {
	MStatus stat;

	// If asked for the outputSurface then compute it
	if (plug == density_file_out) {
		MDataHandle input_handle = data.inputValue(density_file);
		MDataHandle output_handle = data.outputValue(density_file_out);

		const MString& value = input_handle.asString();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == density_scale_out) {
		MDataHandle input_handle = data.inputValue(density_scale);
		MDataHandle output_handle = data.outputValue(density_scale_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == density_offset_out) {
		MDataHandle input_handle = data.inputValue(density_offset);
		MDataHandle output_handle = data.outputValue(density_offset_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == density_read_mode_out) {
		MDataHandle input_handle = data.inputValue(density_read_mode);
		MDataHandle output_handle = data.outputValue(density_read_mode_out);

		const int& value = input_handle.asShort();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_file_out) {
		MDataHandle input_handle = data.inputValue(temperature_file);
		MDataHandle output_handle = data.outputValue(temperature_file_out);

		const MString& value = input_handle.asString();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_scale_out) {
		MDataHandle input_handle = data.inputValue(temperature_scale);
		MDataHandle output_handle = data.outputValue(temperature_scale_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_offset_out) {
		MDataHandle input_handle = data.inputValue(temperature_offset);
		MDataHandle output_handle = data.outputValue(temperature_offset_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_read_mode_out) {
		MDataHandle input_handle = data.inputValue(temperature_read_mode);
		MDataHandle output_handle = data.outputValue(temperature_read_mode_out);

		const int& value = input_handle.asShort();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == interpolation_mode_out) {
		MDataHandle input_handle = data.inputValue(interpolation_mode);
		MDataHandle output_handle = data.outputValue(interpolation_mode_out);

		const int& value = input_handle.asShort();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == fuel_type_out) {
		MDataHandle input_handle = data.inputValue(fuel_type);
		MDataHandle output_handle = data.outputValue(fuel_type_out);

		const int& value = input_handle.asShort();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == visual_adaptation_factor_out) {
		MDataHandle input_handle = data.inputValue(visual_adaptation_factor);
		MDataHandle output_handle = data.outputValue(
				visual_adaptation_factor_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == intensity_out) {
		MDataHandle input_handle = data.inputValue(intensity);
		MDataHandle output_handle = data.outputValue(intensity_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == shadow_threshold_out) {
		MDataHandle input_handle = data.inputValue(shadow_threshold);
		MDataHandle output_handle = data.outputValue(shadow_threshold_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == decay_out) {
		MDataHandle input_handle = data.inputValue(decay);
		MDataHandle output_handle = data.outputValue(decay_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == march_increment_out) {
		MDataHandle input_handle = data.inputValue(march_increment);
		MDataHandle output_handle = data.outputValue(march_increment_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == cast_shadows_out) {
		MDataHandle input_handle = data.inputValue(cast_shadows);
		MDataHandle output_handle = data.outputValue(cast_shadows_out);

		const bool& value = input_handle.asBool();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == high_samples_out) {
		MDataHandle input_handle = data.inputValue(high_samples);
		MDataHandle output_handle = data.outputValue(high_samples_out);

		const int& value = input_handle.asInt();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}

	return MS::kUnknownParameter;
}

void *FireControlNode::creator() {
	return new FireControlNode();
}

MStatus FireControlNode::initialize() {
	MFnNumericAttribute nAttr;
	MFnTypedAttribute tAttr;
	MFnEnumAttribute eAttr;
	MFnStringData stringFn;

	density_file = tAttr.create("density_file", "df", MFnData::kString,
			stringFn.create("Density file path"));

	density_scale = nAttr.create("density_scale", "ds", MFnNumericData::kFloat,
			1e12f);
	nAttr.setSoftMin(0);
	nAttr.setSoftMax(1e15);

	density_offset = nAttr.create("density_offset", "do",
			MFnNumericData::kFloat, 0.0f);
	nAttr.setSoftMin(0);
	nAttr.setSoftMax(100);

	density_read_mode = eAttr.create("density_read_mode", "drm", 1);
	eAttr.addField("ASCII Single Value", 0);
	eAttr.addField("Binary Only Red", 1);
	eAttr.addField("Binary Max RGB", 2);
	eAttr.addField("ASCII Uintah", 3);

	temperature_file = tAttr.create("temperature_file", "tf", MFnData::kString,
			stringFn.create("Temperature file path"));

	temperature_scale = nAttr.create("temperature_scale", "ts",
			MFnNumericData::kFloat, 500.0f);
	nAttr.setSoftMin(0);
	nAttr.setSoftMax(10000);

	temperature_offset = nAttr.create("temperature_offset", "to",
			MFnNumericData::kFloat, 0.0f);
	nAttr.setSoftMin(0);
	nAttr.setSoftMax(100);

	temperature_read_mode = eAttr.create("temperature_read_mode", "trm", 2);
	eAttr.addField("ASCII Single Value", 0);
	eAttr.addField("Binary Only Red", 1);
	eAttr.addField("Binary Max RGB", 2);
	eAttr.addField("ASCII Uintah", 3);

	interpolation_mode = eAttr.create("interpolation_mode", "im", 0);
	eAttr.addField("None", 0);
	eAttr.addField("Trilinear", 1);

	fuel_type = eAttr.create("fuel_type", "ft", 1);
	eAttr.addField("Black Body", 0);
	eAttr.addField("Propane", 1);
	eAttr.addField("Acetylene", 2);
	eAttr.addField("Copper-Green", 3);
	eAttr.addField("Sulfur-Purple", 4);

	visual_adaptation_factor = nAttr.create("visual_adaptation_factor", "vaf",
			MFnNumericData::kFloat, 0);
	nAttr.setMin(0);
	nAttr.setMax(1);

	intensity = nAttr.create("intensity", "int", MFnNumericData::kFloat, 1.0f);
	nAttr.setSoftMin(0);
	nAttr.setSoftMax(10);

	shadow_threshold = nAttr.create("shadow_threshold", "st",
			MFnNumericData::kFloat, 0.0f);
	nAttr.setSoftMin(0);
	nAttr.setSoftMax(0.01);

	decay = nAttr.create("decay", "d", MFnNumericData::kFloat, 2.0f);
	nAttr.setMin(0);
	nAttr.setSoftMax(3);

	march_increment = nAttr.create("march_increment", "mi",
			MFnNumericData::kFloat, 0.05f);
	nAttr.setMin(0);
	nAttr.setSoftMax(1);

	cast_shadows = nAttr.create("cast_shadows", "cs", MFnNumericData::kBoolean,
			false);

	high_samples = nAttr.create("high_samples", "hs", MFnNumericData::kInt, 8);
	nAttr.setMin(0);
	nAttr.setSoftMax(500);

	// Outputs
	density_file_out = tAttr.create("density_file_out", "dfo",
			MFnData::kString);
	do_output(tAttr);

	density_scale_out = nAttr.create("density_scale_out", "dso",
			MFnNumericData::kFloat);
	do_output(nAttr);

	density_offset_out = nAttr.create("density_offset_out", "doo",
			MFnNumericData::kFloat);
	do_output(nAttr);

	density_read_mode_out = eAttr.create("density_read_mode_out", "drmo");
	do_output(nAttr);

	temperature_file_out = tAttr.create("temperature_file_out", "tfo",
			MFnData::kString);
	do_output(tAttr);

	temperature_scale_out = nAttr.create("temperature_scale_out", "tso",
			MFnNumericData::kFloat);
	do_output(nAttr);

	temperature_offset_out = nAttr.create("temperature_offset_out", "too",
			MFnNumericData::kFloat);
	do_output(nAttr);

	temperature_read_mode_out = eAttr.create("temperature_read_mode_out",
			"trmo");
	do_output(eAttr);

	interpolation_mode_out = eAttr.create("interpolation_mode_out", "imo");
	do_output(eAttr);

	fuel_type_out = eAttr.create("fuel_type_out", "fto");
	do_output(eAttr);

	visual_adaptation_factor_out = nAttr.create("visual_adaptation_factor_out",
			"vafo", MFnNumericData::kFloat);
	do_output(nAttr);

	intensity_out = nAttr.create("intensity_out", "into",
			MFnNumericData::kFloat);
	do_output(nAttr);

	shadow_threshold_out = nAttr.create("shadow_threshold_out", "sto",
			MFnNumericData::kFloat);
	do_output(nAttr);

	decay_out = nAttr.create("decay_out", "do", MFnNumericData::kFloat);
	do_output(nAttr);

	march_increment_out = nAttr.create("march_increment_out", "mio",
			MFnNumericData::kFloat);
	do_output(nAttr);

	cast_shadows_out = nAttr.create("cast_shadows_out", "cso",
			MFnNumericData::kBoolean);
	do_output(nAttr);

	high_samples_out = nAttr.create("high_samples_out", "hso",
			MFnNumericData::kInt);
	do_output(nAttr);

	addAttribute(density_file);
	addAttribute(density_scale);
	addAttribute(density_offset);
	addAttribute(density_read_mode);
	addAttribute(temperature_file);
	addAttribute(temperature_scale);
	addAttribute(temperature_offset);
	addAttribute(temperature_read_mode);
	addAttribute(interpolation_mode);
	addAttribute(fuel_type);
	addAttribute(visual_adaptation_factor);
	addAttribute(intensity);
	addAttribute(shadow_threshold);
	addAttribute(decay);
	addAttribute(march_increment);
	addAttribute(cast_shadows);
	addAttribute(high_samples);

	// Outputs
	addAttribute(density_file_out);
	addAttribute(density_scale_out);
	addAttribute(density_offset_out);
	addAttribute(density_read_mode_out);
	addAttribute(temperature_file_out);
	addAttribute(temperature_scale_out);
	addAttribute(temperature_offset_out);
	addAttribute(temperature_read_mode_out);
	addAttribute(interpolation_mode_out);
	addAttribute(fuel_type_out);
	addAttribute(visual_adaptation_factor_out);
	addAttribute(intensity_out);
	addAttribute(shadow_threshold_out);
	addAttribute(decay_out);
	addAttribute(march_increment_out);
	addAttribute(cast_shadows_out);
	addAttribute(high_samples_out);

	attributeAffects(density_file, density_file_out);
	attributeAffects(density_scale, density_scale_out);
	attributeAffects(density_offset, density_offset_out);
	attributeAffects(density_read_mode, density_read_mode_out);
	attributeAffects(temperature_file, temperature_file_out);
	attributeAffects(temperature_scale, temperature_scale_out);
	attributeAffects(temperature_offset, temperature_offset_out);
	attributeAffects(temperature_read_mode, temperature_read_mode_out);
	attributeAffects(interpolation_mode, interpolation_mode_out);
	attributeAffects(fuel_type, fuel_type_out);
	attributeAffects(visual_adaptation_factor, visual_adaptation_factor_out);
	attributeAffects(intensity, intensity_out);
	attributeAffects(shadow_threshold, shadow_threshold_out);
	attributeAffects(decay, decay_out);
	attributeAffects(march_increment, march_increment_out);
	attributeAffects(cast_shadows, cast_shadows_out);
	attributeAffects(high_samples, high_samples_out);

	return MS::kSuccess;
}

void FireControlNode::do_output(MFnAttribute& attr) {
	attr.setHidden(true);
	attr.setStorable(false);
}
